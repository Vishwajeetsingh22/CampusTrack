import logging
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
from config import Config

logger = logging.getLogger("campustrack.db")

_client = None

def get_client():
    """Returns a singleton PyMongo MongoClient instance."""
    global _client
    if _client is None:
        try:
            logger.info(f"Connecting to MongoDB at {Config.MONGO_URI}...")
            _client = MongoClient(
                Config.MONGO_URI,
                serverSelectionTimeoutMS=Config.MONGO_SERVER_SELECTION_TIMEOUT_MS,
                connectTimeoutMS=Config.MONGO_CONNECT_TIMEOUT_MS,
            )
            # Verify the connection with a quick ping
            _client.admin.command("ping")
            logger.info("Successfully connected to MongoDB server.")
        except (ConnectionFailure, ServerSelectionTimeoutError) as err:
            logger.error(f"Failed to connect to MongoDB: {err}")
            raise
    return _client

def get_db():
    """Returns the CampusTrack database instance."""
    client = get_client()
    return client[Config.MONGO_DB_NAME]

def close_db():
    """Closes the PyMongo client connection."""
    global _client
    if _client is not None:
        _client.close()
        _client = None
        logger.info("MongoDB connection closed.")

def check_db_health():
    """Checks MongoDB server connection and reports database statistics."""
    try:
        client = get_client()
        # Ping the server
        client.admin.command("ping")
        db = client[Config.MONGO_DB_NAME]
        
        # Gather collection stats
        collection_names = db.list_collection_names()
        stats = {
            "status": "healthy",
            "database": Config.MONGO_DB_NAME,
            "connected": True,
            "collections": {
                name: db[name].count_documents({}) for name in ["students", "attendance", "marks", "users"] if name in collection_names
            },
            "all_collections": collection_names
        }
        return True, stats
    except Exception as e:
        logger.error(f"MongoDB health check failed: {e}")
        return False, {
            "status": "unhealthy",
            "database": Config.MONGO_DB_NAME,
            "connected": False,
            "error": str(e)
        }

def init_db(app=None):
    """Initializes schema validators and indexes."""
    from .schema_validator import setup_schema_validators
    from .indexes import setup_indexes

    db = get_db()
    logger.info("Initializing CampusTrack database schema validators and indexes...")
    setup_schema_validators(db)
    setup_indexes(db)
    logger.info("Database initialization completed successfully.")
