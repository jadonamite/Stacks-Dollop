
;; Time-Lock Vault
;; Utility: Forces user to save STX until a specific block height

(define-map vaults principal uint) 
(define-map balances principal uint) 

;; 1. Lock Funds
(define-public (lock (amount uint) (duration uint))
  (let
    (
      (unlock-height (+ block-height duration))
      (caller tx-sender)
    )
    ;; Transfer STX from user to contract
    (try! (stx-transfer? amount caller (as-contract tx-sender)))
    
    ;; Record the data
    (map-set vaults caller unlock-height)
    (map-set balances caller amount)
    
    ;; Emit event for Chainhook to pick up
    (print {event: "locked", user: caller, amount: amount, unlock: unlock-height})
    (ok true)
  )
)

;; 2. Unlock Funds
(define-public (unlock)
  (let
    (
      (caller tx-sender)
      (unlock-height (unwrap! (map-get? vaults caller) (err u404)))
      (amount (unwrap! (map-get? balances caller) (err u404)))
    )
    ;; Check if time has passed
    (asserts! (>= block-height unlock-height) (err u100)) 
    
    ;; Return funds
    (try! (as-contract (stx-transfer? amount tx-sender caller)))
    
    ;; Clean up
    (map-delete vaults caller)
    (map-delete balances caller)
    (print {event: "unlocked", user: caller, amount: amount})
    (ok true)
  )
)

