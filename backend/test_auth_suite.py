import unittest
import os
from datetime import datetime, timezone

from config import Config
from app import create_app
from db.connection import get_db

class TestAuthConfig(Config):
    TESTING = True
    MONGO_DB_NAME = "campustrack_test_auth"
    JWT_SECRET_KEY = "test-secret-key-for-auth-unit-tests"

class CampusTrackAuthTestSuite(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = create_app(TestAuthConfig)
        cls.client = cls.app.test_client()

    def setUp(self):
        self.db = get_db()
        # Seed test student
        if not self.db.students.find_one({"student_id": "STU9901"}):
            self.db.students.insert_one({
                "student_id": "STU9901",
                "name": "Jordan Hayes",
                "email": "jordan.hayes@campus.edu",
                "course": "Computer Science",
                "semester": 4,
                "active": True,
                "created_at": datetime.now(timezone.utc),
                "updated_at": datetime.now(timezone.utc)
            })

    def tearDown(self):
        # Clean up test users
        self.db.users.delete_many({"email": {"$regex": ".*@testauth.edu"}})
        self.db.students.delete_many({"student_id": "STU9901"})

    def test_01_register_student_success(self):
        res = self.client.post("/api/auth/register", json={
            "email": "jordan@testauth.edu",
            "password": "Password123!",
            "full_name": "Jordan Hayes",
            "role": "student",
            "student_id": "STU9901"
        })
        self.assertEqual(res.status_code, 201)
        data = res.get_json()
        self.assertTrue(data["success"])
        self.assertFalse(data["data"]["user"]["is_verified"])
        self.assertTrue(len(data["data"]["verification_token"]) > 20)

    def test_02_register_duplicate_email_fails(self):
        # Register first
        self.client.post("/api/auth/register", json={
            "email": "duplicate@testauth.edu",
            "password": "Password123!",
            "full_name": "User One",
            "role": "admin"
        })
        # Attempt second
        res = self.client.post("/api/auth/register", json={
            "email": "duplicate@testauth.edu",
            "password": "Password123!",
            "full_name": "User Two",
            "role": "admin"
        })
        self.assertEqual(res.status_code, 400)
        data = res.get_json()
        self.assertFalse(data["success"])
        self.assertIn("already exists", data["error"])

    def test_03_login_unverified_account_fails(self):
        self.client.post("/api/auth/register", json={
            "email": "unverified@testauth.edu",
            "password": "Password123!",
            "full_name": "Unverified User",
            "role": "admin"
        })

        res = self.client.post("/api/auth/login", json={
            "identifier": "unverified@testauth.edu",
            "password": "Password123!"
        })
        self.assertEqual(res.status_code, 403)
        data = res.get_json()
        self.assertIn("not been verified", data["error"])

    def test_04_verify_email_and_login(self):
        reg_res = self.client.post("/api/auth/register", json={
            "email": "verifytest@testauth.edu",
            "password": "Password123!",
            "full_name": "Verify Tester",
            "role": "admin"
        })
        token = reg_res.get_json()["data"]["verification_token"]

        # Verify email
        verify_res = self.client.post("/api/auth/verify-email", json={"token": token})
        self.assertEqual(verify_res.status_code, 200)
        self.assertTrue(verify_res.get_json()["success"])

        # Login
        login_res = self.client.post("/api/auth/login", json={
            "identifier": "verifytest@testauth.edu",
            "password": "Password123!"
        })
        self.assertEqual(login_res.status_code, 200)
        jwt_token = login_res.get_json()["data"]["token"]
        self.assertTrue(len(jwt_token) > 30)

        # Access /api/auth/me with Bearer token
        me_res = self.client.get("/api/auth/me", headers={"Authorization": f"Bearer {jwt_token}"})
        self.assertEqual(me_res.status_code, 200)
        me_data = me_res.get_json()["data"]
        self.assertEqual(me_data["email"], "verifytest@testauth.edu")
        self.assertTrue(me_data["is_verified"])

    def test_05_password_reset_flow(self):
        # Register and verify
        reg_res = self.client.post("/api/auth/register", json={
            "email": "pwdreset@testauth.edu",
            "password": "OldPassword123!",
            "full_name": "Reset Tester",
            "role": "admin"
        })
        token = reg_res.get_json()["data"]["verification_token"]
        self.client.post("/api/auth/verify-email", json={"token": token})

        # Request reset
        forgot_res = self.client.post("/api/auth/forgot-password", json={"email": "pwdreset@testauth.edu"})
        self.assertEqual(forgot_res.status_code, 200)
        reset_token = forgot_res.get_json()["data"]["reset_token"]

        # Execute reset
        reset_res = self.client.post("/api/auth/reset-password", json={
            "token": reset_token,
            "new_password": "NewSecretPassword2026!"
        })
        self.assertEqual(reset_res.status_code, 200)

        # Old password should fail
        old_login = self.client.post("/api/auth/login", json={
            "identifier": "pwdreset@testauth.edu",
            "password": "OldPassword123!"
        })
        self.assertEqual(old_login.status_code, 401)

        # New password should succeed
        new_login = self.client.post("/api/auth/login", json={
            "identifier": "pwdreset@testauth.edu",
            "password": "NewSecretPassword2026!"
        })
        self.assertEqual(new_login.status_code, 200)

if __name__ == "__main__":
    unittest.main()
