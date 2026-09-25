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
GO
