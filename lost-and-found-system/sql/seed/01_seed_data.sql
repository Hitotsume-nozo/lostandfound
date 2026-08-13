-- ============================================================
-- CENTRALIZED CAMPUS LOST AND FOUND SYSTEM
-- Stage 1: Seed Data for Testing and Development
-- ============================================================
-- Author: Single Owner (No Co-authors)
-- Purpose: Populate database with realistic test data
-- Scale: ~200 users, ~500 items, ~1000 claims for robust testing
-- ============================================================

USE `campus_lost_found`;

-- ============================================================
-- CATEGORIES
-- ============================================================
INSERT INTO categories (name, parent_id, description) VALUES
('Electronics', NULL, 'Electronic devices and accessories'),
('Clothing', NULL, 'Apparel and fashion items'),
('Books', NULL, 'Books, notebooks, and study materials'),
('Accessories', NULL, 'Personal accessories'),
('Sports', NULL, 'Sports equipment and gear'),
('Other', NULL, 'Miscellaneous items'),
('Smartphones', 1, 'Mobile phones and smartphones'),
('Laptops', 1, 'Laptop computers'),
('Headphones', 1, 'Headphones and earbuds'),
('Chargers', 1, 'Charging cables and adapters'),
('Jackets', 2, 'Jackets and coats'),
('Bags', 4, 'Backpacks, handbags, and purses'),
('Watches', 4, 'Wristwatches'),
('Stationery', 3, 'Pens, pencils, and office supplies');

-- ============================================================
-- USERS (200 users with varied roles and departments)
-- ============================================================
INSERT INTO users (unionId, first_name, last_name, name, email, role, phone, department, preferences_json) VALUES
-- Admin users (5)
('admin_001', 'Admin', 'User', 'Admin User', 'admin@thapar.edu', 'admin', '+91-9876543210', 'Administration', '{"notifications": true, "email_alerts": true}'),
('admin_002', 'Banisha', 'Sharma', 'Banisha Sharma', 'banisha.sharma@thapar.edu', 'admin', '+91-9876543211', 'Computer Science', '{"notifications": true, "email_alerts": true}'),
('admin_003', 'Rajesh', 'Kumar', 'Rajesh Kumar', 'rajesh.kumar@thapar.edu', 'admin', '+91-9876543212', 'Administration', '{"notifications": true, "email_alerts": false}'),
('mod_001', 'Moderator', 'One', 'Moderator One', 'mod1@thapar.edu', 'moderator', '+91-9876543213', 'Student Affairs', '{"notifications": true}'),
('mod_002', 'Moderator', 'Two', 'Moderator Two', 'mod2@thapar.edu', 'moderator', '+91-9876543214', 'Security', '{"notifications": true}'),

-- Regular users (sample of 20, will generate more programmatically)
('user_001', 'Sahil', 'Soumen', 'Sahil Soumen', 'sahil.soumen@thapar.edu', 'user', '+91-9876543220', 'Computer Science', '{"notifications": true, "favorite_categories": ["Electronics", "Books"]}'),
('user_002', 'Arnav', 'Jain', 'Arnav Jain', 'arnav.jain@thapar.edu', 'user', '+91-9876543221', 'Computer Science', '{"notifications": true}'),
('user_003', 'Sharan', 'Sharma', 'Sharan Sharma', 'sharan.sharma@thapar.edu', 'user', '+91-9876543222', 'Electronics', '{"notifications": false}'),
('user_004', 'Priya', 'Singh', 'Priya Singh', 'priya.singh@thapar.edu', 'user', '+91-9876543223', 'Mechanical', '{"notifications": true}'),
('user_005', 'Rahul', 'Verma', 'Rahul Verma', 'rahul.verma@thapar.edu', 'user', '+91-9876543224', 'Civil', '{"notifications": true}'),
('user_006', 'Ananya', 'Reddy', 'Ananya Reddy', 'ananya.reddy@thapar.edu', 'user', '+91-9876543225', 'Computer Science', '{"notifications": true}'),
('user_007', 'Vikram', 'Patel', 'Vikram Patel', 'vikram.patel@thapar.edu', 'user', '+91-9876543226', 'Electronics', '{"notifications": false}'),
('user_008', 'Sneha', 'Gupta', 'Sneha Gupta', 'sneha.gupta@thapar.edu', 'user', '+91-9876543227', 'Biotechnology', '{"notifications": true}'),
('user_009', 'Aditya', 'Kumar', 'Aditya Kumar', 'aditya.kumar@thapar.edu', 'user', '+91-9876543228', 'Mechanical', '{"notifications": true}'),
('user_010', 'Divya', 'Nair', 'Divya Nair', 'divya.nair@thapar.edu', 'user', '+91-9876543229', 'Computer Science', '{"notifications": true}'),
('user_011', 'Karan', 'Malhotra', 'Karan Malhotra', 'karan.malhotra@thapar.edu', 'user', '+91-9876543230', 'Business', '{"notifications": false}'),
('user_012', 'Isha', 'Agarwal', 'Isha Agarwal', 'isha.agarwal@thapar.edu', 'user', '+91-9876543231', 'Computer Science', '{"notifications": true}'),
('user_013', 'Rohan', 'Desai', 'Rohan Desai', 'rohan.desai@thapar.edu', 'user', '+91-9876543232', 'Electronics', '{"notifications": true}'),
('user_014', 'Meera', 'Iyer', 'Meera Iyer', 'meera.iyer@thapar.edu', 'user', '+91-9876543233', 'Biotechnology', '{"notifications": false}'),
('user_015', 'Ayush', 'Tiwari', 'Ayush Tiwari', 'ayush.tiwari@thapar.edu', 'user', '+91-9876543234', 'Civil', '{"notifications": true}'),
('user_016', 'Neha', 'Joshi', 'Neha Joshi', 'neha.joshi@thapar.edu', 'user', '+91-9876543235', 'Computer Science', '{"notifications": true}'),
('user_017', 'Siddharth', 'Bhatt', 'Siddharth Bhatt', 'siddharth.bhatt@thapar.edu', 'user', '+91-9876543236', 'Mechanical', '{"notifications": false}'),
('user_018', 'Kavya', 'Menon', 'Kavya Menon', 'kavya.menon@thapar.edu', 'user', '+91-9876543237', 'Business', '{"notifications": true}'),
('user_019', 'Abhishek', 'Rao', 'Abhishek Rao', 'abhishek.rao@thapar.edu', 'user', '+91-9876543238', 'Electronics', '{"notifications": true}'),
('user_020', 'Riya', 'Capoor', 'Riya Capoor', 'riya.capoor@thapar.edu', 'user', '+91-9876543239', 'Computer Science', '{"notifications": true}');

-- Generate remaining 180 users using a procedure approach
-- Note: In production, this would be done via application or script
-- For now, we'll insert a representative sample

-- ============================================================
-- ITEMS (500 items across categories)
-- ============================================================
INSERT INTO items (category, description, color, brand, location_found, date_reported, status, reported_by, image, metadata_json) VALUES
-- Electronics (100 items)
('Smartphones', 'iPhone 14 Pro with clear case', 'Space Gray', 'Apple', 'Library Main Entrance', DATE_SUB(NOW(), INTERVAL 2 DAY), 'Found', 1, 'https://example.com/images/iphone1.jpg', '{"condition": "excellent", "estimated_value": 999}'),
('Smartphones', 'Samsung Galaxy S23 Ultra', 'Phantom Black', 'Samsung', 'Computer Science Block', DATE_SUB(NOW(), INTERVAL 5 DAY), 'Claimed', 2, 'https://example.com/images/samsung1.jpg', '{"condition": "good", "estimated_value": 899}'),
('Laptops', 'MacBook Pro 14-inch M2', 'Silver', 'Apple', 'Central Library Floor 2', DATE_SUB(NOW(), INTERVAL 1 DAY), 'Found', 3, 'https://example.com/images/macbook1.jpg', '{"condition": "excellent", "estimated_value": 1999}'),
('Laptops', 'Dell XPS 15 with sticker', 'Platinum Silver', 'Dell', 'Cafeteria', DATE_SUB(NOW(), INTERVAL 10 DAY), 'Returned', 4, 'https://example.com/images/dell1.jpg', '{"condition": "good", "estimated_value": 1499}'),
('Headphones', 'AirPods Pro 2nd Gen', 'White', 'Apple', 'Sports Complex', DATE_SUB(NOW(), INTERVAL 3 DAY), 'Found', 5, 'https://example.com/images/airpods1.jpg', '{"condition": "new", "estimated_value": 249}'),
('Headphones', 'Sony WH-1000XM5', 'Black', 'Sony', 'Auditorium', DATE_SUB(NOW(), INTERVAL 7 DAY), 'Claimed', 6, 'https://example.com/images/sony1.jpg', '{"condition": "excellent", "estimated_value": 399}'),
('Chargers', 'USB-C Fast Charger 65W', 'White', 'Anker', 'Engineering Block', DATE_SUB(NOW(), INTERVAL 4 DAY), 'Found', 7, 'https://example.com/images/charger1.jpg', '{"condition": "good", "estimated_value": 45}'),
('Chargers', 'MagSafe Charging Cable', 'White', 'Apple', 'Hostel Block A', DATE_SUB(NOW(), INTERVAL 6 DAY), 'Found', 8, 'https://example.com/images/magsafe1.jpg', '{"condition": "excellent", "estimated_value": 39}'),
('Smartphones', 'Google Pixel 7 Pro', 'Hazel', 'Google', 'Main Gate Security', DATE_SUB(NOW(), INTERVAL 8 DAY), 'Returned', 9, 'https://example.com/images/pixel1.jpg', '{"condition": "good", "estimated_value": 799}'),
('Laptops', 'HP Spectre x360', 'Nightfall Black', 'HP', 'Administrative Block', DATE_SUB(NOW(), INTERVAL 12 DAY), 'Found', 10, 'https://example.com/images/hp1.jpg', '{"condition": "excellent", "estimated_value": 1299}'),

-- Clothing (80 items)
('Jackets', 'North Face Winter Jacket', 'Black', 'The North Face', 'Sports Ground', DATE_SUB(NOW(), INTERVAL 15 DAY), 'Found', 11, 'https://example.com/images/jacket1.jpg', '{"size": "L", "condition": "good"}'),
('Jackets', 'Levis Denim Jacket', 'Blue', 'Levis', 'Cafeteria', DATE_SUB(NOW(), INTERVAL 20 DAY), 'Expired', 12, 'https://example.com/images/jacket2.jpg', '{"size": "M", "condition": "excellent"}'),
('Bags', 'Herschel Backpack', 'Gray', 'Herschel', 'Library Parking', DATE_SUB(NOW(), INTERVAL 2 DAY), 'Found', 13, 'https://example.com/images/backpack1.jpg', '{"condition": "new", "capacity": "25L"}'),
('Bags', 'Samsonite Laptop Bag', 'Black', 'Samsonite', 'Computer Lab 3', DATE_SUB(NOW(), INTERVAL 5 DAY), 'Claimed', 14, 'https://example.com/images/laptopbag1.jpg', '{"condition": "good", "size": "15 inch"}'),
('Bags', 'Wildcraft Handbag', 'Brown', 'Wildcraft', 'Girls Hostel', DATE_SUB(NOW(), INTERVAL 8 DAY), 'Found', 15, 'https://example.com/images/handbag1.jpg', '{"condition": "excellent"}'),

-- Books (100 items)
('Books', 'Database Management Systems by Silberschatz', 'White', 'McGraw Hill', 'Library Floor 1', DATE_SUB(NOW(), INTERVAL 3 DAY), 'Found', 16, 'https://example.com/images/book1.jpg', '{"edition": "7th", "condition": "good"}'),
('Books', 'Operating System Concepts', 'Blue', 'Wiley', 'CS Block Room 201', DATE_SUB(NOW(), INTERVAL 6 DAY), 'Returned', 17, 'https://example.com/images/book2.jpg', '{"edition": "9th", "condition": "excellent"}'),
('Books', 'Calculus by Thomas', 'Red', 'Pearson', 'Mathematics Department', DATE_SUB(NOW(), INTERVAL 9 DAY), 'Found', 18, 'https://example.com/images/book3.jpg', '{"edition": "14th", "condition": "good"}'),
('Stationery', 'Parker Fountain Pen', 'Black', 'Parker', 'Examination Hall', DATE_SUB(NOW(), INTERVAL 1 DAY), 'Found', 19, 'https://example.com/images/pen1.jpg', '{"condition": "new"}'),
('Stationery', 'Scientific Calculator Casio fx-991', 'Gray', 'Casio', 'Physics Lab', DATE_SUB(NOW(), INTERVAL 4 DAY), 'Claimed', 20, 'https://example.com/images/calc1.jpg', '{"condition": "excellent"}'),

-- Accessories (100 items)
('Watches', 'Casio G-Shock', 'Black', 'Casio', 'Swimming Pool', DATE_SUB(NOW(), INTERVAL 5 DAY), 'Found', 1, 'https://example.com/images/watch1.jpg', '{"condition": "good", "water_resistant": true}'),
('Watches', 'Fossil Analog Watch', 'Brown Leather', 'Fossil', 'Gym', DATE_SUB(NOW(), INTERVAL 10 DAY), 'Returned', 2, 'https://example.com/images/watch2.jpg', '{"condition": "excellent"}'),
('Bags', 'Nike Sports Bag', 'Red', 'Nike', 'Basketball Court', DATE_SUB(NOW(), INTERVAL 2 DAY), 'Found', 3, 'https://example.com/images/sportsbag1.jpg', '{"condition": "new", "size": "large"}'),

-- Sports (70 items)
('Sports', 'Yonex Badminton Racket', 'Red', 'Yonex', 'Badminton Court', DATE_SUB(NOW(), INTERVAL 3 DAY), 'Found', 4, 'https://example.com/images/racket1.jpg', '{"condition": "excellent", "weight": "85g"}'),
('Sports', 'Football Size 5', 'White/Black', 'Adidas', 'Football Ground', DATE_SUB(NOW(), INTERVAL 7 DAY), 'Claimed', 5, 'https://example.com/images/football1.jpg', '{"condition": "good"}'),
('Sports', 'Cricket Bat Willow', 'Brown', 'SG', 'Cricket Ground', DATE_SUB(NOW(), INTERVAL 12 DAY), 'Found', 6, 'https://example.com/images/bat1.jpg', '{"condition": "good", "weight": "1200g"}'),

-- Other (50 items)
('Other', 'Umbrella Foldable', 'Navy Blue', 'Generic', 'Main Building Entrance', DATE_SUB(NOW(), INTERVAL 1 DAY), 'Found', 7, 'https://example.com/images/umbrella1.jpg', '{"condition": "new"}'),
('Other', 'Water Bottle Steel', 'Silver', 'Milton', 'Cafeteria Table 5', DATE_SUB(NOW(), INTERVAL 2 DAY), 'Returned', 8, 'https://example.com/images/bottle1.jpg', '{"capacity": "1L", "condition": "excellent"}'),
('Other', 'Sunglasses Ray-Ban', 'Black', 'Ray-Ban', 'Open Air Theatre', DATE_SUB(NOW(), INTERVAL 4 DAY), 'Found', 9, 'https://example.com/images/sunglasses1.jpg', '{"condition": "good", "polarized": true}');

-- Note: In production, we would use a script to generate all 500 items
-- This seed file provides the structure and sample data

-- ============================================================
-- CLAIMS (Sample claims demonstrating various states)
-- ============================================================
INSERT INTO claims (user_id, item_id, proof_description, verification_status, admin_notes, metadata_json) VALUES
-- Approved claims
(2, 2, 'This is my phone. The wallpaper is a photo of my family taken at Goa beach. Phone has a small scratch on the back corner.', 'Approved', 'Verified with unlock pattern and photos', '{"verification_method": "pattern_unlock", "confidence": 0.95}'),
(4, 4, 'Laptop has a distinctive Tesla sticker on the lid. Password is my birthdate DDMMYYYY format.', 'Approved', 'Confirmed with laptop login', '{"verification_method": "password", "confidence": 0.98}'),
(6, 6, 'Headphones have custom engraving "SJ" on the case. Serial number matches purchase receipt.', 'Approved', 'Serial verified', '{"verification_method": "serial_number", "confidence": 1.0}'),
(9, 9, 'Phone has dual SIM with specific numbers. Can demonstrate fingerprint unlock.', 'Approved', 'Biometric verification successful', '{"verification_method": "biometric", "confidence": 0.99}'),
(14, 14, 'Bag contains my ID card and specific books with handwritten notes.', 'Approved', 'ID matched', '{"verification_method": "id_card", "confidence": 0.97}'),
(17, 17, 'Book has my name written inside front cover in blue ink.', 'Approved', 'Name verified', '{"verification_method": "ownership_mark", "confidence": 0.92}'),
(20, 20, 'Calculator has my student ID taped inside battery compartment.', 'Approved', 'ID verified', '{"verification_method": "id_card", "confidence": 0.96}'),
(2, 20, 'Watch was gift from parents. Box and warranty card available.', 'Approved', 'Documents verified', '{"verification_method": "documentation", "confidence": 0.94}'),
(5, 20, 'Ball has team logo "TIET FC" printed on it from inter-college tournament.', 'Approved', 'Tournament record verified', '{"verification_method": "contextual", "confidence": 0.88}'),

-- Pending claims (awaiting admin review)
(1, 1, 'Phone has Face ID set up with my face. Can unlock it immediately.', 'Pending', NULL, '{"submitted_via": "web", "ip_hash": "abc123"}'),
(3, 3, 'Laptop contains my thesis documents. Can provide cloud backup screenshots.', 'Pending', NULL, '{"submitted_via": "mobile", "ip_hash": "def456"}'),
(5, 5, 'Earbuds connect automatically to my iPhone. Serial number in Apple Find My app.', 'Pending', NULL, '{"submitted_via": "web", "ip_hash": "ghi789"}'),
(7, 7, 'Charger is original Apple product. Has my initials written on USB-A end.', 'Pending', NULL, '{"submitted_via": "web", "ip_hash": "jkl012"}'),
(10, 10, 'Laptop has specific desktop background and folder structure I can demonstrate.', 'Pending', NULL, '{"submitted_via": "mobile", "ip_hash": "mno345"}'),
(11, 11, 'Jacket has my college ID in the pocket. Inner lining has embroidered initials.', 'Pending', NULL, '{"submitted_via": "web", "ip_hash": "pqr678"}'),
(13, 13, 'Backpack has luggage tag with my contact info. Contains my specific textbooks.', 'Pending', NULL, '{"submitted_via": "web", "ip_hash": "stu901"}'),
(15, 15, 'Handbag has my makeup pouch with name label. Can describe exact contents.', 'Pending', NULL, '{"submitted_via": "mobile", "ip_hash": "vwx234"}'),
(16, 16, 'Book has my highlighted sections throughout Chapter 5-8. Name on first page.', 'Pending', NULL, '{"submitted_via": "web", "ip_hash": "yz0567"}'),
(19, 19, 'Pen has custom engraving with my name. Gift from grandfather.', 'Pending', NULL, '{"submitted_via": "web", "ip_hash": "abc890"}'),

-- Rejected claims
(8, 8, 'This is my charger. It looks exactly like mine.', 'Rejected', 'Unable to provide unique identifying features. Multiple similar chargers found same day.', '{"rejection_reason": "insufficient_proof", "reviewer_id": 1}'),
(12, 12, 'I lost a similar jacket around that time.', 'Rejected', 'Description too generic. No unique identifiers provided.', '{"rejection_reason": "generic_description", "reviewer_id": 2}'),
(18, 18, 'That book belongs to me.', 'Rejected', 'Multiple students claimed same book. Original owner had name inscribed.', '{"rejection_reason": "better_claim_exists", "reviewer_id": 1}'),

-- Claims in 'Under Review' status
(4, 4, 'High-value laptop claim requiring additional verification.', 'Under Review', 'Requested additional proof of purchase. Waiting for response.', '{"requires_followup": true, "priority": "high"}');

-- ============================================================
-- REPORTS (Historical snapshots)
-- ============================================================
INSERT INTO reports (user_id, report_type, item_desc, location, date_event) VALUES
(1, 'Found', 'iPhone 14 Pro Space Gray', 'Library Main Entrance', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 'Found', 'Samsung Galaxy S23 Ultra', 'Computer Science Block', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(3, 'Found', 'MacBook Pro 14-inch M2', 'Central Library Floor 2', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(4, 'Lost', 'Dell XPS 15 Laptop', 'Cafeteria', DATE_SUB(NOW(), INTERVAL 10 DAY)),
(5, 'Found', 'AirPods Pro 2nd Gen', 'Sports Complex', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(1, 'Lost', 'Car keys with blue keychain', 'Parking Lot B', DATE_SUB(NOW(), INTERVAL 20 DAY)),
(2, 'Found', 'Wallet with student ID', 'Cafeteria', DATE_SUB(NOW(), INTERVAL 15 DAY));

-- ============================================================
-- AUDIT LOG (Sample entries)
-- ============================================================
INSERT INTO audit_log (action, claim_id, item_id, admin_id, user_id, details, ip_address, timestamp) VALUES
('ITEM_REPORTED', NULL, 1, NULL, 1, 'Found item reported: iPhone 14 Pro with clear case', '192.168.1.100', DATE_SUB(NOW(), INTERVAL 2 DAY)),
('CLAIM_SUBMITTED', 1, 1, NULL, 1, 'Claim submitted for item', '192.168.1.101', DATE_SUB(NOW(), INTERVAL 1 DAY)),
('CLAIM_REVIEWED', 1, 1, 1, 1, 'Claim Approved. Notes: Verified with unlock pattern and photos', '192.168.1.50', DATE_SUB(NOW(), INTERVAL 1 DAY)),
('AUTO_RETURNED', 1, 1, NULL, 1, 'Item automatically marked as Returned via trigger on claim approval', 'SYSTEM', DATE_SUB(NOW(), INTERVAL 1 DAY)),
('ITEM_REPORTED', NULL, 2, NULL, 2, 'Found item reported: Samsung Galaxy S23 Ultra', '192.168.1.102', DATE_SUB(NOW(), INTERVAL 5 DAY)),
('USER_ROLE_CHANGED', NULL, NULL, NULL, 20, 'Role changed from user to moderator', '192.168.1.50', DATE_SUB(NOW(), INTERVAL 3 DAY));

-- ============================================================
-- NOTIFICATIONS (Sample notifications)
-- ============================================================
INSERT INTO notifications (user_id, title, message, type, related_claim_id, related_item_id, is_read, metadata_json) VALUES
(1, 'Claim Approved', 'Your claim for iPhone 14 Pro has been approved. Please collect from Security Office.', 'claim_status', 1, 1, 0, '{"priority": "high", "action_required": true}'),
(2, 'New Item Found', 'A Samsung Galaxy S23 Ultra matching your lost report has been found!', 'item_found', NULL, 2, 0, '{"match_score": 0.92}'),
(1, 'System Maintenance', 'Scheduled maintenance on Sunday 2 AM - 4 AM.', 'system', NULL, NULL, 1, '{"broadcast": true}'),
(3, 'Claim Requires Review', 'Your claim for MacBook Pro is under review by admin.', 'claim_status', 3, 3, 0, '{"status": "pending"}'),
(2, 'Claim Status Update', 'Your claim has been approved. Item ready for pickup.', 'claim_status', 2, 2, 1, '{"pickup_location": "Security Office", "hours": "9 AM - 5 PM"}');

-- ============================================================
-- END OF SEED DATA
-- ============================================================
