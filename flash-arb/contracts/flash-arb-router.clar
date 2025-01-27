;; Router contract for handling multi-hop trades in flash arbitrage

;; Import core traits
(use-trait sip-010-trait 
    .flash-arb-v1.sip-010-trait)

(use-trait dex-trait 
    .flash-arb-v1.dex-trait)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-PATH (err u201))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u202))
(define-constant ERR-INSUFFICIENT-OUTPUT (err u203))
(define-constant ERR-MAX-PATH-LENGTH (err u204))
(define-constant ERR-SAME-DEX (err u205))
(define-constant ERR-ZERO-AMOUNT (err u206))
(define-constant ERR-TOKEN-NOT-WHITELISTED (err u207))
(define-constant ERR-DEX-NOT-WHITELISTED (err u208))

;; Constants
(define-constant MAX-PATH-LENGTH u5)
(define-constant BASIS-POINTS u10000)
(define-constant MAX-SLIPPAGE u200) ;; 2% max slippage

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-map route-cache 
    {token-in: principal, token-out: principal} 
    {best-path: (list 5 principal), last-update: uint})

;; Data structures for trade paths
(define-map path-scores
    {path-id: uint}
    {score: uint, success-count: uint, fail-count: uint})

;; Read-only functions
(define-read-only (get-path-score (path-id uint))
    (default-to {score: u0, success-count: u0, fail-count: u0}
        (map-get? path-scores {path-id: path-id})))

(define-read-only (get-cached-route (token-in principal) (token-out principal))
    (map-get? route-cache {token-in: token-in, token-out: token-out}))

;; Route optimization functions
(define-private (calculate-path-score (success-count uint) (fail-count uint))
    (let (
        (total-trades (+ success-count fail-count))
        (base-score u1000))
        (if (is-eq total-trades u0)
            base-score
            (/ (* base-score success-count) total-trades))))

(define-private (validate-dex-path (dex-1 principal) (dex-2 principal))
    (and 
        (contract-call? .flash-arb-v1 is-dex-whitelisted dex-1)
        (contract-call? .flash-arb-v1 is-dex-whitelisted dex-2)
        (not (is-eq dex-1 dex-2))))

;; Multi-hop trade execution
(define-public (execute-multi-hop-trade
    (flash-loan <sip-010-trait>)
    (amount uint)
    (dex-1 <dex-trait>)
    (dex-2 <dex-trait>)
    (min-output uint))
    (let (
        (initial-balance (try! (contract-call? flash-loan get-balance tx-sender)))
        (dex-1-principal (as-contract tx-sender))
        (dex-2-principal (as-contract tx-sender)))
        (begin
            ;; Validate inputs
            (asserts! (> amount u0) ERR-ZERO-AMOUNT)
            (asserts! (validate-dex-path dex-1-principal dex-2-principal) ERR-INVALID-PATH)
            
            ;; Execute flash loan and trades
            (try! (contract-call? .flash-arb-v1 execute-flash-loan
                flash-loan
                amount
                dex-1
                dex-2
                none))
            
            ;; Verify output amount meets minimum
            (asserts! (>= (- (try! (contract-call? flash-loan get-balance tx-sender)) 
                            initial-balance)
                         min-output)
                     ERR-INSUFFICIENT-OUTPUT)
            
            ;; Update path statistics
            (map-set path-scores
                {path-id: u2}  ;; Two-hop trade
                {score: (calculate-path-score 
                            (+ (get success-count (get-path-score u2)) u1)
                            (get fail-count (get-path-score u2))),
                 success-count: (+ (get success-count (get-path-score u2)) u1),
                 fail-count: (get fail-count (get-path-score u2))})
            
            (ok true))))

;; Price impact calculation and slippage check
(define-public (check-slippage
    (dex <dex-trait>) 
    (token-in principal) 
    (token-out principal) 
    (amount-in uint) 
    (min-out uint))
    (let (
        (pair-details (try! (contract-call? dex get-pair-details token-in token-out)))
        (expected-out (/ (* amount-in (get balance-y pair-details))
                        (+ (get balance-x pair-details) amount-in)))
        (slippage (* (- expected-out min-out) BASIS-POINTS)))
        (asserts! (<= slippage MAX-SLIPPAGE) ERR-SLIPPAGE-TOO-HIGH)
        (ok expected-out)))

;; Cache management
(define-public (update-route-cache
    (token-in principal) 
    (token-out principal) 
    (new-path (list 5 principal)))
    (begin
        ;; Check authorization
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        
        ;; Validate input tokens are whitelisted
        (asserts! (contract-call? .flash-arb-v1 is-token-whitelisted token-in) ERR-TOKEN-NOT-WHITELISTED)
        (asserts! (contract-call? .flash-arb-v1 is-token-whitelisted token-out) ERR-TOKEN-NOT-WHITELISTED)
        
        ;; Validate path
        (let 
            ((path-length (len new-path)))
            ;; Check path length
            (asserts! (and (> path-length u0) (<= path-length MAX-PATH-LENGTH)) ERR-INVALID-PATH)
            
            ;; Validate each DEX in path is whitelisted
            (asserts! 
                (fold check-dex-in-path new-path true)
                ERR-DEX-NOT-WHITELISTED)
            
            ;; Update cache if all validations pass
            (map-set route-cache
                {token-in: token-in, token-out: token-out}
                {best-path: new-path, 
                 last-update: block-height})
            (ok true))))

;; Helper functions
(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner)))

(define-private (check-dex-in-path (dex principal) (prev-result bool))
    (and 
        prev-result 
        (contract-call? .flash-arb-v1 is-dex-whitelisted dex)))

;; Initialize contract
(begin
    (var-set contract-owner tx-sender))