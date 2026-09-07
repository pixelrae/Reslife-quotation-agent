-- Sample data reflecting the two quotes produced by the original prototype
-- (RES-26-001 and RES-26-002), for demoing/testing the new system.
-- Run AFTER database/schema.sql.

INSERT INTO customers (full_name, email, company_name, billing_address) VALUES
    ('nina', 'nina@gmail.com', 'food lovers', '32 howard road')
ON CONFLICT (email) DO NOTHING;

-- RES-26-002: both items were already in the catalogue, so no custom item
-- requests are needed for this seed example.
INSERT INTO quotes (quote_number, customer_id, event_date, event_time, delivery_location, delivery_method, status, subtotal, grand_total, contains_estimate_flag, valid_until)
VALUES (
    'RES-26-002',
    (SELECT id FROM customers WHERE email = 'nina@gmail.com'),
    '2026-04-03', '13:00', 'UWC Life sciences', 'N/A',
    'sent', 3450.00, 3450.00, false, now() + interval '14 days'
);

INSERT INTO quote_items (quote_id, menu_item_id, item_name_raw, quantity, unit_price, line_total, is_custom, price_status)
VALUES
    ((SELECT id FROM quotes WHERE quote_number = 'RES-26-002'),
     (SELECT id FROM menu_items WHERE name = 'Chicken Burger + Chips'),
     'Chicken Burger + Chips', 30, 55.00, 1650.00, false, 'confirmed'),
    ((SELECT id FROM quotes WHERE quote_number = 'RES-26-002'),
     (SELECT id FROM menu_items WHERE name = 'Beef Burger + Chips'),
     'Beef Burger + Chips', 30, 60.00, 1800.00, false, 'confirmed');

-- Example of a quote that DOES hit the custom-item path, to demo the
-- functionality that didn't exist in the original prototype.
INSERT INTO quotes (quote_number, customer_id, event_date, event_time, delivery_location, delivery_method, status, subtotal, grand_total, contains_estimate_flag, valid_until)
VALUES (
    'RES-26-014',
    (SELECT id FROM customers WHERE email = 'nina@gmail.com'),
    '2026-05-10', '12:00', 'UWC Life sciences', 'N/A',
    'pending_manager_review', 2850.00, 2850.00, true, now() + interval '14 days'
);

INSERT INTO quote_items (quote_id, menu_item_id, item_name_raw, quantity, unit_price, line_total, is_custom, price_status)
VALUES
    ((SELECT id FROM quotes WHERE quote_number = 'RES-26-014'),
     (SELECT id FROM menu_items WHERE name = 'Chicken Burger + Chips'),
     'Chicken Burger + Chips', 30, 55.00, 1650.00, false, 'confirmed'),
    ((SELECT id FROM quotes WHERE quote_number = 'RES-26-014'),
     NULL, 'Boerewors Roll', 40, 30.00, 1200.00, true, 'estimated_placeholder');

INSERT INTO custom_item_requests (quote_id, quote_item_id, item_name, ai_estimated_price, ai_estimate_source, ai_estimate_confidence)
VALUES (
    (SELECT id FROM quotes WHERE quote_number = 'RES-26-014'),
    (SELECT id FROM quote_items
       WHERE quote_id = (SELECT id FROM quotes WHERE quote_number = 'RES-26-014')
         AND item_name_raw = 'Boerewors Roll'),
    'Boerewors Roll', 30.00,
    'Estimated from typical Cape Town takeaway boerewors roll pricing.', 'medium'
);
