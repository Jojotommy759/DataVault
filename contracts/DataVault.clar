;; DataVault: Scientific Research Data and Methodology Exchange Platform
;; Version: 1.0.0
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-DATASET-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-PUBLISHED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-SAMPLE-SIZE (err u5))
(define-constant ERR-INVALID-RESEARCH-FIELD (err u6))
(define-constant ERR-INVALID-METHODOLOGY (err u7))
(define-constant ERR-INVALID-DATASET-TITLE (err u8))
(define-constant ERR-INVALID-ABSTRACT (err u9))
(define-constant MIN-SAMPLE-SIZE u10)
(define-data-var next-dataset-id uint u1)
(define-map research-repository
    uint
    {
        researcher: principal,
        dataset-title: (string-utf8 50),
        abstract: (string-utf8 200),
        research-field: (string-utf8 15),
        methodology: (string-utf8 10),
        access-status: (string-utf8 15),
        sample-size: uint
    }
)
(define-private (validate-research-field (research-field (string-utf8 15)))
    (or 
        (is-eq research-field u"Biology")
        (is-eq research-field u"Chemistry")
        (is-eq research-field u"Physics")
        (is-eq research-field u"Psychology")
        (is-eq research-field u"Sociology")
        (is-eq research-field u"Medicine")
    )
)
(define-private (validate-methodology (methodology (string-utf8 10)))
    (or 
        (is-eq methodology u"Experimental")
        (is-eq methodology u"Observational")
        (is-eq methodology u"Survey")
        (is-eq methodology u"Meta-Analysis")
        (is-eq methodology u"Case Study")
    )
)
(define-private (validate-text-input (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (publish-dataset 
    (dataset-title (string-utf8 50))
    (abstract (string-utf8 200))
    (research-field (string-utf8 15))
    (methodology (string-utf8 10))
    (sample-size uint)
)
    (let
        (
            (dataset-id (var-get next-dataset-id))
        )
        (asserts! (validate-text-input dataset-title u3 u50) ERR-INVALID-DATASET-TITLE)
        (asserts! (validate-text-input abstract u10 u200) ERR-INVALID-ABSTRACT)
        (asserts! (>= sample-size MIN-SAMPLE-SIZE) ERR-INVALID-SAMPLE-SIZE)
        (asserts! (validate-research-field research-field) ERR-INVALID-RESEARCH-FIELD)
        (asserts! (validate-methodology methodology) ERR-INVALID-METHODOLOGY)
        
        (map-set research-repository dataset-id {
            researcher: tx-sender,
            dataset-title: dataset-title,
            abstract: abstract,
            research-field: research-field,
            methodology: methodology,
            access-status: u"open",
            sample-size: sample-size
        })
        (var-set next-dataset-id (+ dataset-id u1))
        (ok dataset-id)
    )
)
(define-public (embargo-dataset (dataset-id uint))
    (let
        (
            (dataset (unwrap! (map-get? research-repository dataset-id) ERR-DATASET-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get researcher dataset)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get access-status dataset) u"open") ERR-INVALID-STATUS)
        (ok (map-set research-repository dataset-id (merge dataset { access-status: u"embargoed" })))
    )
)
(define-read-only (get-dataset (dataset-id uint))
    (ok (map-get? research-repository dataset-id))
)
(define-read-only (get-researcher (dataset-id uint))
    (ok (get researcher (unwrap! (map-get? research-repository dataset-id) ERR-DATASET-NOT-FOUND)))
)