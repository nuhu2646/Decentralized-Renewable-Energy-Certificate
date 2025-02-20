;; Generation Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))

;; Data Maps
(define-map producers
  { producer-id: uint }
  {
    owner: principal,
    energy-type: (string-ascii 20),
    total-generation: uint
  }
)

(define-map generation-events
  { event-id: uint }
  {
    producer-id: uint,
    amount: uint,
    timestamp: uint
  }
)

(define-data-var producer-nonce uint u0)
(define-data-var event-nonce uint u0)

;; Functions
(define-public (register-producer (energy-type (string-ascii 20)))
  (let
    ((new-producer-id (+ (var-get producer-nonce) u1)))
    (map-set producers
      { producer-id: new-producer-id }
      {
        owner: tx-sender,
        energy-type: energy-type,
        total-generation: u0
      }
    )
    (var-set producer-nonce new-producer-id)
    (ok new-producer-id)
  )
)

(define-public (record-generation (producer-id uint) (amount uint))
  (let
    ((producer (unwrap! (map-get? producers { producer-id: producer-id }) ERR_NOT_FOUND))
     (new-event-id (+ (var-get event-nonce) u1)))
    (asserts! (is-eq (get owner producer) tx-sender) ERR_NOT_AUTHORIZED)
    (map-set generation-events
      { event-id: new-event-id }
      {
        producer-id: producer-id,
        amount: amount,
        timestamp: block-height
      }
    )
    (map-set producers
      { producer-id: producer-id }
      (merge producer { total-generation: (+ (get total-generation producer) amount) })
    )
    (var-set event-nonce new-event-id)
    (ok new-event-id)
  )
)

(define-read-only (get-producer (producer-id uint))
  (map-get? producers { producer-id: producer-id })
)

(define-read-only (get-generation-event (event-id uint))
  (map-get? generation-events { event-id: event-id })
)

(define-read-only (get-total-generation (producer-id uint))
  (match (map-get? producers { producer-id: producer-id })
    producer (ok (get total-generation producer))
    ERR_NOT_FOUND
  )
)
