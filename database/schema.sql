-- ============================================================================
-- ResLife Foods — AI Quotation Agent Database Schema
-- Engine: PostgreSQL 14+ (also runs on MySQL 8+ with minor type changes —
--         see database/README.md for the MySQL notes)
--
-- Design goal: solve the two things the Botpress + Google Sheets + AutoCrat
-- prototype could not do -
--   1. Recognise an order item that is NOT in the current catalogue,
--      auto-estimate a fair Cape Town market price for it as a placeholder,
--      and still let the quote go out without blocking on the manager.
--   2. Let the manager confirm/adjust that price ONCE, and have the system
--      remember it — so the same custom item is a normal catalogue item
--      (with markup applied) the next time a customer asks for it.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. CUSTOMERS
-- ---------------------------------------------------------------------------
CREATE TABLE customers (
    id              SERIAL PRIMARY KEY,
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    phone_number    VARCHAR(30),
    company_name    VARCHAR(150),
    billing_address TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 2. MENU_ITEMS  (the "catalogue" / product database)
-- ---------------------------------------------------------------------------
-- source tracks HOW a price entered the catalogue, which matters for trust
-- and for the ethics section of the assignment (transparency of AI pricing).
CREATE TABLE menu_items (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    category        VARCHAR(80),                 -- e.g. 'Mains', 'Sides', 'Drinks'
    unit_price      NUMERIC(10,2) NOT NULL,
    unit            VARCHAR(40) NOT NULL DEFAULT 'each',
    markup_percent  NUMERIC(5,2) NOT NULL DEFAULT 20.00,
    source          VARCHAR(30)  NOT NULL DEFAULT 'catalog'
                     CHECK (source IN ('catalog', 'ai_estimated', 'manager_confirmed')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_menu_items_name ON menu_items (LOWER(name));

-- ---------------------------------------------------------------------------
-- 3. QUOTES
-- ---------------------------------------------------------------------------
CREATE TABLE quotes (
    id                    SERIAL PRIMARY KEY,
    quote_number          VARCHAR(20) NOT NULL UNIQUE,       -- e.g. RES-26-003
    customer_id           INTEGER NOT NULL REFERENCES customers(id),
    event_date            DATE,
    event_time            TIME,
    delivery_location     VARCHAR(200),
    delivery_method       VARCHAR(60),
    status                VARCHAR(30) NOT NULL DEFAULT 'draft'
                           CHECK (status IN (
                               'draft',
                               'pending_manager_review',  -- contains >=1 custom/estimated item
                               'approved',
                               'sent',
                               'expired',
                               'cancelled'
                           )),
    subtotal              NUMERIC(10,2) NOT NULL DEFAULT 0,
    grand_total            NUMERIC(10,2) NOT NULL DEFAULT 0,
    contains_estimate_flag BOOLEAN NOT NULL DEFAULT FALSE,   -- true while any line is a placeholder price
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    sent_at               TIMESTAMPTZ,
    valid_until            DATE
);

CREATE INDEX idx_quotes_status ON quotes (status);
CREATE INDEX idx_quotes_customer ON quotes (customer_id);

-- ---------------------------------------------------------------------------
-- 4. QUOTE_ITEMS  (line items on a quote)
-- ---------------------------------------------------------------------------
CREATE TABLE quote_items (
    id              SERIAL PRIMARY KEY,
    quote_id        INTEGER NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    menu_item_id    INTEGER REFERENCES menu_items(id),      -- NULL until a custom item is matched/created
    item_name_raw   VARCHAR(200) NOT NULL,                  -- exactly what the customer typed/said
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL,                 -- price used on THIS quote (may be a placeholder)
    line_total      NUMERIC(10,2) NOT NULL,
    is_custom       BOOLEAN NOT NULL DEFAULT FALSE,
    price_status    VARCHAR(30) NOT NULL DEFAULT 'confirmed'
                    CHECK (price_status IN ('confirmed', 'estimated_placeholder', 'awaiting_manager_approval'))
);

CREATE INDEX idx_quote_items_quote ON quote_items (quote_id);

-- ---------------------------------------------------------------------------
-- 5. CUSTOM_ITEM_REQUESTS
-- ---------------------------------------------------------------------------
-- Created automatically the moment the agent can't match an item against
-- menu_items. Holds the AI's estimated price + source, and the manager's
-- final decision. This table is the audit trail behind every AI price guess.
-- ---------------------------------------------------------------------------
CREATE TABLE custom_item_requests (
    id                     SERIAL PRIMARY KEY,
    quote_id               INTEGER NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    quote_item_id          INTEGER NOT NULL REFERENCES quote_items(id) ON DELETE CASCADE,
    item_name              VARCHAR(200) NOT NULL,
    ai_estimated_price     NUMERIC(10,2),
    ai_estimate_source     TEXT,             -- e.g. "web search: avg Cape Town takeaway price for similar item"
    ai_estimate_confidence VARCHAR(20) CHECK (ai_estimate_confidence IN ('low','medium','high')),
    manager_approved_price NUMERIC(10,2),
    manager_markup_percent NUMERIC(5,2),
    status                 VARCHAR(20) NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'approved', 'rejected')),
    resolved_by            VARCHAR(150),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at            TIMESTAMPTZ
);

CREATE INDEX idx_custom_item_requests_status ON custom_item_requests (status);

-- ---------------------------------------------------------------------------
-- 6. PRICE_HISTORY  (audit trail for every catalogue price change)
-- ---------------------------------------------------------------------------
CREATE TABLE price_history (
    id            SERIAL PRIMARY KEY,
    menu_item_id  INTEGER NOT NULL REFERENCES menu_items(id) ON DELETE CASCADE,
    old_price     NUMERIC(10,2),
    new_price     NUMERIC(10,2) NOT NULL,
    changed_by    VARCHAR(150) NOT NULL,        -- 'ai_agent' or the manager's name
    reason        VARCHAR(200),
    changed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- 7. ORDER_STATUS_LOG  (replaces the "spreadsheet of orders coming in")
-- ---------------------------------------------------------------------------
CREATE TABLE order_status_log (
    id          SERIAL PRIMARY KEY,
    quote_id    INTEGER NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    status      VARCHAR(30) NOT NULL,
    note        TEXT,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Convenience view: everything the manager dashboard needs in one query
-- ---------------------------------------------------------------------------
CREATE VIEW v_quotes_awaiting_review AS
SELECT
    q.id                AS quote_id,
    q.quote_number,
    c.full_name         AS customer_name,
    c.email             AS customer_email,
    q.event_date,
    q.grand_total,
    cir.id               AS custom_item_request_id,
    cir.item_name,
    cir.ai_estimated_price,
    cir.ai_estimate_source
FROM quotes q
JOIN customers c              ON c.id = q.customer_id
JOIN custom_item_requests cir ON cir.quote_id = q.id AND cir.status = 'pending'
WHERE q.status = 'pending_manager_review'
ORDER BY q.created_at ASC;

-- ---------------------------------------------------------------------------
-- Seed data: reflects RES-26-001 / RES-26-002 examples from the prototype
-- ---------------------------------------------------------------------------
INSERT INTO menu_items (name, category, unit_price, unit, source) VALUES
    ('Chicken Burger + Chips', 'Mains', 55.00, 'each', 'catalog'),
    ('Beef Burger + Chips',    'Mains', 60.00, 'each', 'catalog');

INSERT INTO customers (full_name, email, company_name, billing_address) VALUES
    ('Nina', 'nina@gmail.com', 'food lovers', '32 howard road');
