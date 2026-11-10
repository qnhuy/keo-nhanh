USE master;
GO

IF DB_ID('Keonhanh') IS NOT NULL
BEGIN
    ALTER DATABASE Keonhanh SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Keonhanh;
END
GO

CREATE DATABASE Keonhanh;
GO

USE Keonhanh;
GO

-- ==========================================================
-- 0. Xóa các bảng cũ nếu đã tồn tại (hỗ trợ chạy lại script an toàn)
-- ==========================================================
IF OBJECT_ID('dbo.AiDailyUsage', 'U') IS NOT NULL DROP TABLE dbo.AiDailyUsage;
IF OBJECT_ID('dbo.Payments', 'U') IS NOT NULL DROP TABLE dbo.Payments;
IF OBJECT_ID('dbo.Notifications', 'U') IS NOT NULL DROP TABLE dbo.Notifications;
IF OBJECT_ID('dbo.Messages', 'U') IS NOT NULL DROP TABLE dbo.Messages;
IF OBJECT_ID('dbo.Invitations', 'U') IS NOT NULL DROP TABLE dbo.Invitations;
IF OBJECT_ID('dbo.JoinRequests', 'U') IS NOT NULL DROP TABLE dbo.JoinRequests;
IF OBJECT_ID('dbo.Matches', 'U') IS NOT NULL DROP TABLE dbo.Matches;
IF OBJECT_ID('dbo.TeamPlayers', 'U') IS NOT NULL DROP TABLE dbo.TeamPlayers;
IF OBJECT_ID('dbo.Teams', 'U') IS NOT NULL DROP TABLE dbo.Teams;
IF OBJECT_ID('dbo.User_profiles', 'U') IS NOT NULL DROP TABLE dbo.User_profiles;
IF OBJECT_ID('dbo.UserProfiles', 'U') IS NOT NULL DROP TABLE dbo.UserProfiles;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'User_profiles') DROP SYNONYM User_profiles;
GO

-- ==========================================================
-- 1. CREATE TABLES (Đã đồng nhất tên bảng theo chuẩn PascalCase số nhiều)
-- ==========================================================

-- 1. Table Users (Tài khoản đăng nhập)
CREATE TABLE Users (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Username NVARCHAR(255) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    Role NVARCHAR(50) DEFAULT 'player',
    IsPaid BIT DEFAULT 0,
    PaidUntil DATETIME NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 2. Table UserProfiles (Hồ sơ người chơi - Đã đồng nhất từ User_profiles)
CREATE TABLE UserProfiles (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL UNIQUE FOREIGN KEY REFERENCES Users(Id),
    Phone NVARCHAR(20) NOT NULL,
    Avatar NVARCHAR(MAX) DEFAULT '',
    FullName NVARCHAR(255) NOT NULL,
    Position NVARCHAR(255) NOT NULL,
    Location NVARCHAR(255) NOT NULL,
    IsLookingForTeam BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 3. Table Teams (Thông tin đội bóng)
CREATE TABLE Teams (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name NVARCHAR(255) NOT NULL,
    Logo NVARCHAR(MAX) DEFAULT '',
    CaptainId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Location NVARCHAR(255) NOT NULL,
    SkillLevel NVARCHAR(50) DEFAULT N'Sơ cấp' CHECK (SkillLevel IN (N'Sơ cấp', N'Trung cấp', N'Chuyên nghiệp')),
    IsRecruiting BIT DEFAULT 1,
    RecruitingStatus NVARCHAR(50) DEFAULT 'Searching' CHECK (RecruitingStatus IN ('Searching', 'Full')),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 4. Table TeamPlayers (Danh sách thành viên của đội bóng - Many-to-Many)
CREATE TABLE TeamPlayers (
    TeamId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Teams(Id),
    UserProfileId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES UserProfiles(Id),
    PRIMARY KEY (TeamId, UserProfileId)
);
GO

-- 5. Table Matches (Kèo đấu)
CREATE TABLE Matches (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    CreatorTeamId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Teams(Id),
    Location NVARCHAR(255) NOT NULL,
    FieldName NVARCHAR(255) NOT NULL,
    Latitude FLOAT,
    Longitude FLOAT,
    PlayTime DATETIME NOT NULL,
    Status NVARCHAR(50) DEFAULT 'open' CHECK (Status IN ('open', 'matched', 'finished', 'cancelled')),
    MatchedWithTeamId UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Teams(Id),
    IsPinned BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 6. Table JoinRequests (Yêu cầu gia nhập đội bóng)
CREATE TABLE JoinRequests (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RequesterId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES UserProfiles(Id),
    TeamId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Teams(Id),
    Status NVARCHAR(50) DEFAULT 'pending' CHECK (Status IN ('pending', 'approved', 'rejected')),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 7. Table Invitations (Lời mời tham gia đội bóng)
CREATE TABLE Invitations (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TeamId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Teams(Id),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Status NVARCHAR(50) DEFAULT 'pending' CHECK (Status IN ('pending', 'accepted', 'rejected')),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 8. Table Messages (Tin nhắn nội bộ của đội)
CREATE TABLE Messages (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    TeamId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Teams(Id),
    SenderId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Content NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 9. Table Notifications (Thông báo người dùng)
CREATE TABLE Notifications (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    Title NVARCHAR(255) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    Type NVARCHAR(50) DEFAULT 'match_matched',
    RelatedId UNIQUEIDENTIFIER NULL,
    IsRead BIT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 10. Table Payments (Lịch sử giao dịch thanh toán PayOS)
CREATE TABLE Payments (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    OrderCode BIGINT NOT NULL UNIQUE,
    Amount INT NOT NULL DEFAULT 29000,
    PackageName NVARCHAR(100) DEFAULT N'Gói Đặc Quyền 1 Tháng',
    Status NVARCHAR(50) DEFAULT 'PENDING' CHECK (Status IN ('PENDING', 'PAID', 'CANCELLED')),
    PaymentUrl NVARCHAR(MAX),
    QrCode NVARCHAR(MAX),
    CreatedAt DATETIME DEFAULT GETDATE(),
    PaidAt DATETIME NULL
);
GO

-- 11. Table AiDailyUsage (Giới hạn lượt hỏi AI trong ngày cho tài khoản Miễn phí)
CREATE TABLE AiDailyUsage (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES Users(Id),
    UsageDate DATE DEFAULT CAST(GETDATE() AS DATE),
    QuestionCount INT DEFAULT 1,
    CONSTRAINT UQ_User_Date UNIQUE (UserId, UsageDate)
);
GO

-- Tạo SYNONYM để hỗ trợ tương thích ngược cho backend/code cũ nếu có truy vấn đến tên cũ 'User_profiles' hoặc 'Notification'
IF NOT EXISTS (SELECT * FROM sys.synonyms WHERE name = 'User_profiles')
BEGIN
    CREATE SYNONYM User_profiles FOR UserProfiles;
END
GO
IF NOT EXISTS (SELECT * FROM sys.synonyms WHERE name = 'Notification')
BEGIN
    CREATE SYNONYM Notification FOR Notifications;
END
GO

-- ==========================================================
-- 2. INSERT SAMPLE DATA (Ít nhất 10 bản ghi cho mỗi bảng)
-- ==========================================================

-- 1. Insert Users (15 records - Mật khẩu mặc định: '123456' đã băm bằng bcrypt)
INSERT INTO Users (Id, Username, Password, Role, CreatedAt, UpdatedAt) VALUES
('10000000-0000-0000-0000-000000000001', 'nguyen_van_a', '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-10 08:00:00', '2026-01-10 08:00:00'),
('10000000-0000-0000-0000-000000000002', 'tran_thi_b',   '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-11 09:30:00', '2026-01-11 09:30:00'),
('10000000-0000-0000-0000-000000000003', 'le_van_c',     '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-12 10:15:00', '2026-01-12 10:15:00'),
('10000000-0000-0000-0000-000000000004', 'pham_hoang_d', '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-15 14:00:00', '2026-01-15 14:00:00'),
('10000000-0000-0000-0000-000000000005', 'hoang_minh_e', '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-18 11:20:00', '2026-01-18 11:20:00'),
('10000000-0000-0000-0000-000000000006', 'vu_quoc_f',    '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-20 16:45:00', '2026-01-20 16:45:00'),
('10000000-0000-0000-0000-000000000007', 'dang_hai_g',   '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-22 08:30:00', '2026-01-22 08:30:00'),
('10000000-0000-0000-0000-000000000008', 'bui_tien_h',   '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-25 15:10:00', '2026-01-25 15:10:00'),
('10000000-0000-0000-0000-000000000009', 'do_tuan_i',    '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-01-28 17:00:00', '2026-01-28 17:00:00'),
('10000000-0000-0000-0000-000000000010', 'ngo_quang_k',  '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'captain', '2026-02-01 09:00:00', '2026-02-01 09:00:00'),
('10000000-0000-0000-0000-000000000011', 'dinh_trong_l', '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'player',  '2026-02-02 10:00:00', '2026-02-02 10:00:00'),
('10000000-0000-0000-0000-000000000012', 'duong_duc_m',  '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'player',  '2026-02-03 11:30:00', '2026-02-03 11:30:00'),
('10000000-0000-0000-0000-000000000013', 'mai_xuan_n',   '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'player',  '2026-02-04 13:45:00', '2026-02-04 13:45:00'),
('10000000-0000-0000-0000-000000000014', 'ly_thanh_p',   '$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'player',  '2026-02-05 15:20:00', '2026-02-05 15:20:00'),
('10000000-0000-0000-0000-000000000015', 'admin_keonhanh','$2b$10$YYIjF72Bc9moajqmBYhZEuEIqldLWbcXhtF7aY5cHTTwzb4787wMq', 'admin',   '2026-01-01 00:00:00', '2026-01-01 00:00:00');
GO

-- 2. Insert UserProfiles (15 records)
INSERT INTO UserProfiles (Id, UserId, Phone, Avatar, FullName, Position, Location, IsLookingForTeam, CreatedAt, UpdatedAt) VALUES
('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '0901234501', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user1', N'Nguyễn Văn An', N'Tiền đạo (ST)', N'Quận 1, TP. Hồ Chí Minh', 0, '2026-01-10 08:05:00', '2026-01-10 08:05:00'),
('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', '0901234502', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user2', N'Trần Thị Bình', N'Tiền vệ trung tâm (CM)', N'Quận Cầu Giấy, Hà Nội', 0, '2026-01-11 09:35:00', '2026-01-11 09:35:00'),
('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', '0901234503', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user3', N'Lê Văn Cường', N'Hậu vệ cánh (RB)', N'Quận Hải Châu, Đà Nẵng', 0, '2026-01-12 10:20:00', '2026-01-12 10:20:00'),
('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', '0901234504', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user4', N'Phạm Hoàng Dũng', N'Trung vệ (CB)', N'Quận Bình Thạnh, TP. Hồ Chí Minh', 0, '2026-01-15 14:05:00', '2026-01-15 14:05:00'),
('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000005', '0901234505', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user5', N'Hoàng Minh Em', N'Thủ môn (GK)', N'Quận Đống Đa, Hà Nội', 0, '2026-01-18 11:25:00', '2026-01-18 11:25:00'),
('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006', '0901234506', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user6', N'Vũ Quốc Phong', N'Tiền vệ cánh (LW)', N'Quận 7, TP. Hồ Chí Minh', 0, '2026-01-20 16:50:00', '2026-01-20 16:50:00'),
('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000007', '0901234507', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user7', N'Đặng Hải Giang', N'Tiền đạo cánh (RW)', N'Quận Sơn Trà, Đà Nẵng', 0, '2026-01-22 08:35:00', '2026-01-22 08:35:00'),
('20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000008', '0901234508', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user8', N'Bùi Tiến Hùng', N'Tiền vệ phòng ngự (CDM)', N'Quận Tân Bình, TP. Hồ Chí Minh', 0, '2026-01-25 15:15:00', '2026-01-25 15:15:00'),
('20000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000009', '0901234509', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user9', N'Đỗ Tuấn Kiệt', N'Tiền vệ công (CAM)', N'Quận Ba Đình, Hà Nội', 0, '2026-01-28 17:05:00', '2026-01-28 17:05:00'),
('20000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000010', '0901234510', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user10', N'Ngô Quang Khánh', N'Hậu vệ cánh (LB)', N'TP. Thủ Đức, TP. Hồ Chí Minh', 0, '2026-02-01 09:05:00', '2026-02-01 09:05:00'),
('20000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000011', '0901234511', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user11', N'Đinh Trọng Luật', N'Tiền vệ cánh (RW)', N'Quận Phú Nhuận, TP. Hồ Chí Minh', 1, '2026-02-02 10:05:00', '2026-02-02 10:05:00'),
('20000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000012', '0901234512', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user12', N'Dương Đức Mạnh', N'Trung vệ (CB)', N'Quận Cầu Giấy, Hà Nội', 1, '2026-02-03 11:35:00', '2026-02-03 11:35:00'),
('20000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000013', '0901234513', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user13', N'Mai Xuân Nam', N'Thủ môn (GK)', N'Quận Ngũ Hành Sơn, Đà Nẵng', 1, '2026-02-04 13:50:00', '2026-02-04 13:50:00'),
('20000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000014', '0901234514', 'https://api.dicebear.com/7.x/avataaars/svg?seed=user14', N'Lý Thành Phát', N'Tiền đạo (ST)', N'Quận 10, TP. Hồ Chí Minh', 1, '2026-02-05 15:25:00', '2026-02-05 15:25:00'),
('20000000-0000-0000-0000-000000000015', '10000000-0000-0000-0000-000000000015', '0901234515', 'https://api.dicebear.com/7.x/avataaars/svg?seed=admin',  N'Quản Trị Viên', N'Hỗ trợ kỹ thuật', N'Quận 1, TP. Hồ Chí Minh', 0, '2026-01-01 00:05:00', '2026-01-01 00:05:00');
GO

-- 3. Insert Teams (10 records)
INSERT INTO Teams (Id, Name, Logo, CaptainId, Location, SkillLevel, IsRecruiting, RecruitingStatus, CreatedAt, UpdatedAt) VALUES
('30000000-0000-0000-0000-000000000001', N'FC Sài Gòn Phố', 'https://picsum.photos/seed/team1/200', '10000000-0000-0000-0000-000000000001', N'Quận 1, TP. Hồ Chí Minh', N'Trung cấp', 1, 'Searching', '2026-01-10 10:00:00', '2026-01-10 10:00:00'),
('30000000-0000-0000-0000-000000000002', N'FC Hà Nội Titans', 'https://picsum.photos/seed/team2/200', '10000000-0000-0000-0000-000000000002', N'Quận Cầu Giấy, Hà Nội', N'Chuyên nghiệp', 1, 'Searching', '2026-01-11 11:00:00', '2026-01-11 11:00:00'),
('30000000-0000-0000-0000-000000000003', N'FC Rồng Vàng Đà Nẵng', 'https://picsum.photos/seed/team3/200', '10000000-0000-0000-0000-000000000003', N'Quận Hải Châu, Đà Nẵng', N'Sơ cấp', 1, 'Searching', '2026-01-12 12:00:00', '2026-01-12 12:00:00'),
('30000000-0000-0000-0000-000000000004', N'FC Kèo Nhanh Allstars', 'https://picsum.photos/seed/team4/200', '10000000-0000-0000-0000-000000000004', N'Quận Bình Thạnh, TP. Hồ Chí Minh', N'Trung cấp', 0, 'Full', '2026-01-15 15:00:00', '2026-01-15 15:00:00'),
('30000000-0000-0000-0000-000000000005', N'FC Chiến Binh Xanh', 'https://picsum.photos/seed/team5/200', '10000000-0000-0000-0000-000000000005', N'Quận Đống Đa, Hà Nội', N'Trung cấp', 1, 'Searching', '2026-01-18 12:00:00', '2026-01-18 12:00:00'),
('30000000-0000-0000-0000-000000000006', N'FC Nam Sài Gòn', 'https://picsum.photos/seed/team6/200', '10000000-0000-0000-0000-000000000006', N'Quận 7, TP. Hồ Chí Minh', N'Sơ cấp', 1, 'Searching', '2026-01-20 17:00:00', '2026-01-20 17:00:00'),
('30000000-0000-0000-0000-000000000007', N'FC Bão Miền Trung', 'https://picsum.photos/seed/team7/200', '10000000-0000-0000-0000-000000000007', N'Quận Sơn Trà, Đà Nẵng', N'Chuyên nghiệp', 0, 'Full', '2026-01-22 09:00:00', '2026-01-22 09:00:00'),
('30000000-0000-0000-0000-000000000008', N'FC Tân Bình Knights', 'https://picsum.photos/seed/team8/200', '10000000-0000-0000-0000-000000000008', N'Quận Tân Bình, TP. Hồ Chí Minh', N'Trung cấp', 1, 'Searching', '2026-01-25 16:00:00', '2026-01-25 16:00:00'),
('30000000-0000-0000-0000-000000000009', N'FC Thăng Long United', 'https://picsum.photos/seed/team9/200', '10000000-0000-0000-0000-000000000009', N'Quận Ba Đình, Hà Nội', N'Trung cấp', 1, 'Searching', '2026-01-28 18:00:00', '2026-01-28 18:00:00'),
('30000000-0000-0000-0000-000000000010', N'FC Thủ Đức Warriors', 'https://picsum.photos/seed/team10/200', '10000000-0000-0000-0000-000000000010', N'TP. Thủ Đức, TP. Hồ Chí Minh', N'Sơ cấp', 1, 'Searching', '2026-02-01 10:00:00', '2026-02-01 10:00:00');
GO

-- 4. Insert TeamPlayers (16 records - Danh sách thành viên đội bóng)
INSERT INTO TeamPlayers (TeamId, UserProfileId) VALUES
('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001'), -- An (Captain) in FC Sài Gòn Phố
('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004'), -- Dũng in FC Sài Gòn Phố
('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002'), -- Bình (Captain) in FC Hà Nội Titans
('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000005'), -- Em in FC Hà Nội Titans
('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003'), -- Cường (Captain) in FC Rồng Vàng Đà Nẵng
('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000007'), -- Giang in FC Rồng Vàng Đà Nẵng
('30000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000004'), -- Dũng (Captain) in FC Kèo Nhanh Allstars
('30000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000008'), -- Hùng in FC Kèo Nhanh Allstars
('30000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000005'), -- Em (Captain) in FC Chiến Binh Xanh
('30000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000009'), -- Kiệt in FC Chiến Binh Xanh
('30000000-0000-0000-0000-000000000006', '20000000-0000-0000-0000-000000000006'), -- Phong (Captain) in FC Nam Sài Gòn
('30000000-0000-0000-0000-000000000006', '20000000-0000-0000-0000-000000000010'), -- Khánh in FC Nam Sài Gòn
('30000000-0000-0000-0000-000000000007', '20000000-0000-0000-0000-000000000007'), -- Giang (Captain) in FC Bão Miền Trung
('30000000-0000-0000-0000-000000000008', '20000000-0000-0000-0000-000000000008'), -- Hùng (Captain) in FC Tân Bình Knights
('30000000-0000-0000-0000-000000000009', '20000000-0000-0000-0000-000000000009'), -- Kiệt (Captain) in FC Thăng Long United
('30000000-0000-0000-0000-000000000010', '20000000-0000-0000-0000-000000000010'); -- Khánh (Captain) in FC Thủ Đức Warriors
GO

-- 5. Insert Matches (10 records - Kèo đấu)
INSERT INTO Matches (Id, CreatorTeamId, Location, FieldName, Latitude, Longitude, PlayTime, Status, MatchedWithTeamId, CreatedAt, UpdatedAt) VALUES
('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', N'Quận 1, TP. Hồ Chí Minh', N'Sân bóng Chảo Lửa', 10.7769, 106.7009, '2026-11-10 18:30:00', 'open', NULL, '2026-11-01 08:00:00', '2026-11-01 08:00:00'),
('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', N'Quận Cầu Giấy, Hà Nội', N'Sân bóng K33', 21.0333, 105.7895, '2026-11-11 19:00:00', 'matched', '30000000-0000-0000-0000-000000000005', '2026-11-01 09:00:00', '2026-11-02 10:00:00'),
('40000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000003', N'Quận Hải Châu, Đà Nẵng', N'Sân bóng Tuyên Sơn', 16.0354, 108.2255, '2026-11-12 17:30:00', 'matched', '30000000-0000-0000-0000-000000000007', '2026-11-01 10:00:00', '2026-11-02 14:00:00'),
('40000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000004', N'Quận Bình Thạnh, TP. Hồ Chí Minh', N'Sân cỏ Chu Văn An', 10.8123, 106.7025, '2026-11-05 20:00:00', 'finished', '30000000-0000-0000-0000-000000000008', '2026-10-28 11:00:00', '2026-11-05 22:00:00'),
('40000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000005', N'Quận Đống Đa, Hà Nội', N'Sân bóng Thành Phát', 21.0182, 105.8239, '2026-11-14 18:00:00', 'open', NULL, '2026-11-02 08:30:00', '2026-11-02 08:30:00'),
('40000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000006', N'Quận 7, TP. Hồ Chí Minh', N'Sân Tao Đàn 2', 10.7321, 106.7214, '2026-11-15 19:30:00', 'matched', '30000000-0000-0000-0000-000000000001', '2026-11-02 15:00:00', '2026-11-03 09:00:00'),
('40000000-0000-0000-0000-000000000007', '30000000-0000-0000-0000-000000000007', N'Quận Sơn Trà, Đà Nẵng', N'Sân Sơn Trà Sport', 16.0825, 108.2432, '2026-11-03 17:00:00', 'finished', '30000000-0000-0000-0000-000000000003', '2026-10-25 10:00:00', '2026-11-03 19:00:00'),
('40000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000008', N'Quận Tân Bình, TP. Hồ Chí Minh', N'Sân Celadon Sport', 10.7985, 106.6452, '2026-11-16 20:30:00', 'cancelled', NULL, '2026-11-03 11:00:00', '2026-11-03 16:00:00'),
('40000000-0000-0000-0000-000000000009', '30000000-0000-0000-0000-000000000009', N'Quận Ba Đình, Hà Nội', N'Sân bóng Quần Ngựa', 21.0389, 105.8198, '2026-11-18 18:30:00', 'open', NULL, '2026-11-03 14:00:00', '2026-11-03 14:00:00'),
('40000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000010', N'TP. Thủ Đức, TP. Hồ Chí Minh', N'Sân Nông Lâm Stadium', 10.8712, 106.7905, '2026-11-20 17:00:00', 'open', NULL, '2026-11-04 08:00:00', '2026-11-04 08:00:00');
GO

-- 6. Insert JoinRequests (10 records - Yêu cầu gia nhập đội bóng)
INSERT INTO JoinRequests (Id, RequesterId, TeamId, Status, CreatedAt, UpdatedAt) VALUES
('50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000001', 'pending',  '2026-11-01 08:30:00', '2026-11-01 08:30:00'),
('50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000002', 'pending',  '2026-11-01 09:15:00', '2026-11-01 09:15:00'),
('50000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000013', '30000000-0000-0000-0000-000000000003', 'pending',  '2026-11-01 10:45:00', '2026-11-01 10:45:00'),
('50000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000014', '30000000-0000-0000-0000-000000000004', 'rejected', '2026-11-01 11:20:00', '2026-11-01 14:00:00'),
('50000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000006', 'approved', '2026-11-02 08:00:00', '2026-11-02 10:30:00'),
('50000000-0000-0000-0000-000000000006', '20000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000005', 'approved', '2026-11-02 09:30:00', '2026-11-02 12:00:00'),
('50000000-0000-0000-0000-000000000007', '20000000-0000-0000-0000-000000000013', '30000000-0000-0000-0000-000000000007', 'rejected', '2026-11-02 14:00:00', '2026-11-02 16:00:00'),
('50000000-0000-0000-0000-000000000008', '20000000-0000-0000-0000-000000000014', '30000000-0000-0000-0000-000000000008', 'pending',  '2026-11-03 08:15:00', '2026-11-03 08:15:00'),
('50000000-0000-0000-0000-000000000009', '20000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000010', 'pending',  '2026-11-03 10:00:00', '2026-11-03 10:00:00'),
('50000000-0000-0000-0000-000000000010', '20000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000009', 'approved', '2026-11-03 15:30:00', '2026-11-03 18:00:00');
GO

-- 7. Insert Invitations (10 records - Lời mời tham gia đội bóng)
INSERT INTO Invitations (Id, TeamId, UserId, Status, CreatedAt, UpdatedAt) VALUES
('60000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000011', 'pending',  '2026-11-01 08:00:00', '2026-11-01 08:00:00'),
('60000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000012', 'accepted', '2026-11-01 09:00:00', '2026-11-01 11:00:00'),
('60000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000013', 'rejected', '2026-11-01 10:00:00', '2026-11-01 12:30:00'),
('60000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000014', 'pending',  '2026-11-01 14:00:00', '2026-11-01 14:00:00'),
('60000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000012', 'pending',  '2026-11-02 08:30:00', '2026-11-02 08:30:00'),
('60000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000011', 'accepted', '2026-11-02 09:15:00', '2026-11-02 13:00:00'),
('60000000-0000-0000-0000-000000000007', '30000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000013', 'pending',  '2026-11-02 11:00:00', '2026-11-02 11:00:00'),
('60000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000014', 'accepted', '2026-11-02 15:00:00', '2026-11-02 17:30:00'),
('60000000-0000-0000-0000-000000000009', '30000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000012', 'rejected', '2026-11-03 09:00:00', '2026-11-03 10:15:00'),
('60000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000014', 'pending',  '2026-11-03 14:00:00', '2026-11-03 14:00:00');
GO

-- 8. Insert Messages (12 records - Tin nhắn nội bộ của đội)
INSERT INTO Messages (Id, TeamId, SenderId, Content, CreatedAt) VALUES
('70000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', N'Chào anh em, tuần này thứ 7 đá lúc 18h30 tại sân Chảo Lửa nhé!', '2026-11-04 08:30:00'),
('70000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000004', N'Em có mặt đúng giờ nha đội trưởng!', '2026-11-04 08:35:00'),
('70000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', N'Nhớ mang đồng phục màu xanh nhé mọi người.', '2026-11-04 08:40:00'),
('70000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', N'Kèo tối chủ nhật với FC Chiến Binh Xanh đã chốt xong.', '2026-11-04 09:00:00'),
('70000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', N'Sân K33 mặt cỏ mới làm lại rất êm, mang giày TF đi nhé.', '2026-11-04 09:15:00'),
('70000000-0000-0000-0000-000000000006', '30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', N'Đội mình đang thiếu 1 thủ môn, ai quen thủ môn rủ thêm giúp anh nhé.', '2026-11-04 10:00:00'),
('70000000-0000-0000-0000-000000000007', '30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000007', N'Để em hỏi thằng bạn cùng lớp xem nó rảnh không.', '2026-11-04 10:10:00'),
('70000000-0000-0000-0000-000000000008', '30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', N'Trận vừa rồi anh em đá gắn kết và phòng ngự rất chắc chắn!', '2026-11-04 11:00:00'),
('70000000-0000-0000-0000-000000000009', '30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000008', N'Tiền đạo trận này dứt điểm bén thật, 2 cú sút xa đều thành bàn.', '2026-11-04 11:15:00'),
('70000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000005', N'Lịch tập tuần này thứ Năm lúc 17h30 tại sân Thành Phát nhé.', '2026-11-04 14:00:00'),
('70000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000009', N'Em tan ca lúc 17h, sẽ chạy qua luôn ạ.', '2026-11-04 14:10:00'),
('70000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006', N'Mọi người kiểm tra size áo đấu mới để mình chốt đơn in nhé.', '2026-11-04 15:00:00');
GO

-- 9. Insert Notifications (12 records - Thông báo người dùng)
INSERT INTO Notifications (Id, UserId, Title, Message, Type, RelatedId, IsRead, CreatedAt) VALUES
('80000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', N'Ghép kèo thành công! ⚽', N'Đội FC Nam Sài Gòn đã nhận kèo thi đấu tại Sân Tao Đàn 2 lúc 19:30 ngày 15/11/2026.', 'match_matched', '40000000-0000-0000-0000-000000000006', 0, '2026-11-04 09:00:00'),
('80000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', N'Yêu cầu gia nhập mới 📋', N'Cầu thủ Đinh Trọng Luật đã gửi yêu cầu gia nhập FC Sài Gòn Phố.', 'join_request', '50000000-0000-0000-0000-000000000001', 0, '2026-11-04 08:30:00'),
('80000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', N'Nhắc nhở trận đấu ⏰', N'Trận đấu giao hữu tại Sân bóng Chảo Lửa sắp diễn ra vào cuối tuần.', 'system', '40000000-0000-0000-0000-000000000001', 1, '2026-11-03 10:00:00'),
('80000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000002', N'Đối thủ đã nhận kèo! 🔥', N'Đội FC Chiến Binh Xanh đã chấp nhận lời thách đấu tại Sân K33 lúc 19:00 ngày 11/11/2026.', 'match_matched', '40000000-0000-0000-0000-000000000002', 0, '2026-11-04 10:00:00'),
('80000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', N'Lời mời được chấp nhận ✅', N'Cầu thủ Dương Đức Mạnh đã đồng ý gia nhập FC Hà Nội Titans.', 'team_invitation', '60000000-0000-0000-0000-000000000002', 1, '2026-11-03 11:00:00'),
('80000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000003', N'Kèo đấu đã có đối thủ! ⚡', N'Đội FC Bão Miền Trung đã nhận kèo thi đấu tại Sân Tuyên Sơn lúc 17:30 ngày 12/11/2026.', 'match_matched', '40000000-0000-0000-0000-000000000003', 0, '2026-11-04 11:00:00'),
('80000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000004', N'Kết quả trận đấu 🏆', N'Trận đấu với FC Tân Bình Knights đã kết thúc thành công với tỉ số 5-2.', 'match_result', '40000000-0000-0000-0000-000000000004', 1, '2026-11-02 22:00:00'),
('80000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000005', N'Đã ghép đối thành công! ⚽', N'Đội FC Hà Nội Titans đã xác nhận ghép kèo tại Sân K33.', 'match_matched', '40000000-0000-0000-0000-000000000002', 0, '2026-11-04 12:00:00'),
('80000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000011', N'Lời mời vào đội bóng 🏆', N'Đội trưởng Nguyễn Văn An đã mời bạn tham gia FC Sài Gòn Phố.', 'team_invitation', '60000000-0000-0000-0000-000000000001', 0, '2026-11-04 08:00:00'),
('80000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000011', N'Yêu cầu gia nhập được duyệt 🎉', N'Bạn đã chính thức trở thành thành viên của FC Nam Sài Gòn.', 'join_request', '50000000-0000-0000-0000-000000000005', 1, '2026-11-02 10:30:00'),
('80000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000012', N'Yêu cầu gia nhập được duyệt 🎉', N'FC Chiến Binh Xanh đã chấp thuận yêu cầu xin vào đội của bạn.', 'join_request', '50000000-0000-0000-0000-000000000006', 1, '2026-11-02 12:00:00'),
('80000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000012', N'Lời mời vào đội bóng 💌', N'FC Thăng Long United đã gửi lời mời gia nhập đội bóng đến bạn.', 'team_invitation', '60000000-0000-0000-0000-000000000009', 0, '2026-11-03 09:00:00');
GO
