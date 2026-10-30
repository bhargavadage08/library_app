"""
Comprehensive automated tests for the Book Reading & Pagination Backend
"""
import os
import sys

# Ensure app directory is accessible
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "app"))

from fastapi.testclient import TestClient
try:
    from app.main import app
except ImportError:
    from main import app

def run_tests():
    print("=" * 60)
    print("STARTING BOOK READING BACKEND VERIFICATION TESTS")
    print("=" * 60)

    with TestClient(app) as client:
        # 1. Health check
        print("\n[1] Testing Health Check Endpoint...")
        r = client.get("/health")
        assert r.status_code == 200, f"Health check failed: {r.status_code}"
        print(f"    PASSED: {r.json()}")

        # 2. Test Get Book Content (Real text retrieval)
        print("\n[2] Testing GET /api/v1/books/84/content (Frankenstein)...")
        r = client.get("/api/v1/books/84/content")
        assert r.status_code == 200, f"Content fetch failed: {r.status_code} - {r.text}"
        data = r.json()
        assert data["book_id"] == 84
        assert len(data["content"]) > 50000, "Content too short, should be full book"
        assert "Frankenstein" in data["title"] or "Frankenstein" in data["content"]
        print(f"    PASSED: Retrieved {data['total_length']} characters of real book text")

        # 3. Test Paginated Content - Page 1
        print("\n[3] Testing GET /api/v1/books/84/pages?page=1&pageSize=2500...")
        r = client.get("/api/v1/books/84/pages?page=1&pageSize=2500")
        assert r.status_code == 200
        p1 = r.json()
        assert p1["page"] == 1
        assert p1["has_prev"] is False
        assert p1["has_next"] is True
        assert p1["total_pages"] > 50
        print(f"    PASSED: Page 1 of {p1['total_pages']} (Length: {len(p1['content'])})")

        # 4. Test Paginated Content - Page 2
        print("\n[4] Testing GET /api/books/84/pages?page=2 (Using /api prefix alias)...")
        r = client.get("/api/books/84/pages?page=2&pageSize=2500")
        assert r.status_code == 200
        p2 = r.json()
        assert p2["page"] == 2
        assert p2["has_prev"] is True
        assert p2["has_next"] is True
        assert p1["content"] != p2["content"], "Page 1 and Page 2 content must be different"
        print(f"    PASSED: Page 2 of {p2['total_pages']} retrieved successfully")

        # 5. Test Reading Progress PUT & GET
        print("\n[5] Testing Progress Sync (PUT & GET)...")
        device_id = "test-verification-device-42"
        put_payload = {"current_page": 15, "total_pages": p1["total_pages"]}
        r_put = client.put(
            "/api/v1/books/84/progress",
            json=put_payload,
            headers={"X-Device-Id": device_id},
        )
        assert r_put.status_code == 200, f"PUT progress failed: {r_put.text}"
        prog_data = r_put.json()
        assert prog_data["current_page"] == 15
        assert prog_data["percentage"] > 0
        print(f"    PASSED PUT: Saved page {prog_data['current_page']} ({prog_data['percentage']}%)")

        r_get = client.get(
            "/api/v1/books/84/progress",
            headers={"X-Device-Id": device_id},
        )
        assert r_get.status_code == 200
        get_prog = r_get.json()
        assert get_prog["current_page"] == 15
        print(f"    PASSED GET: Restored progress successfully at page {get_prog['current_page']}")

        # 6. Test Out-of-bounds Page Clamping
        print("\n[6] Testing Page Boundary Clamping (page=9999)...")
        r_clamp = client.get("/api/v1/books/84/pages?page=9999")
        assert r_clamp.status_code == 200
        clamp_data = r_clamp.json()
        assert clamp_data["page"] == clamp_data["total_pages"]
        assert clamp_data["has_next"] is False
        print(f"    PASSED: Out-of-bounds page clamped to last page ({clamp_data['page']})")

        # 7. Test Unavailable Book Handling
        print("\n[7] Testing Unavailable / Invalid Book ID...")
        r_err = client.get("/api/v1/books/99999999/pages")
        assert r_err.status_code == 404, f"Expected 404, got {r_err.status_code}"
        print(f"    PASSED: 404 error returned gracefully: {r_err.json()['detail']}")

    print("\n" + "=" * 60)
    print("ALL TESTS PASSED SUCCESSFULLY!")
    print("=" * 60)

if __name__ == "__main__":
    run_tests()
