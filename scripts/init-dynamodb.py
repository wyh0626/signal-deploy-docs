#!/usr/bin/env python3
"""Initialize DynamoDB Local tables for Signal Server."""

import os
import sys
import time

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

ENDPOINT = os.environ.get("DYNAMODB_ENDPOINT", "http://localhost:8000")
REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
RECREATE_ON_MISMATCH = os.environ.get("DYNAMODB_RECREATE_ON_MISMATCH", "1") != "0"

client = boto3.client(
    "dynamodb",
    endpoint_url=ENDPOINT,
    region_name=REGION,
    aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID", "local"),
    aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY", "local"),
    config=Config(retries={"max_attempts": 3}),
)


def table(
    name,
    hash_key_name,
    hash_key_type,
    range_key_name=None,
    range_key_type=None,
    attr_defs=None,
    gsis=None,
):
    attribute_definitions = list(attr_defs or [(hash_key_name, hash_key_type)])
    key_schema = [{"AttributeName": hash_key_name, "KeyType": "HASH"}]

    if range_key_name is not None:
        if range_key_type is None:
            raise ValueError(f"{name}: range_key_type is required when range_key_name is set")
        key_schema.append({"AttributeName": range_key_name, "KeyType": "RANGE"})
        if attr_defs is None:
            attribute_definitions.append((range_key_name, range_key_type))

    payload = {
        "TableName": name,
        "BillingMode": "PAY_PER_REQUEST",
        "AttributeDefinitions": [
            {"AttributeName": attr_name, "AttributeType": attr_type}
            for attr_name, attr_type in attribute_definitions
        ],
        "KeySchema": key_schema,
    }

    if gsis:
        payload["GlobalSecondaryIndexes"] = []
        for gsi in gsis:
            payload["GlobalSecondaryIndexes"].append(
                {
                    "IndexName": gsi["IndexName"],
                    "KeySchema": gsi["KeySchema"],
                    "Projection": gsi.get("Projection", {"ProjectionType": "KEYS_ONLY"}),
                }
            )

    return payload


TABLES = [
    table(
        "Example_Accounts",
        "U",
        "B",
        attr_defs=[("U", "B"), ("UL", "B")],
        gsis=[
            {
                "IndexName": "ul_to_u",
                "KeySchema": [{"AttributeName": "UL", "KeyType": "HASH"}],
            }
        ],
    ),
    table("Example_Backups", "U", "B"),
    table("Example_ClientReleases", "P", "S", "V", "S"),
    table(
        "Example_DeletedAccounts",
        "P",
        "S",
        attr_defs=[("P", "S"), ("U", "B")],
        gsis=[
            {
                "IndexName": "u_to_p",
                "KeySchema": [{"AttributeName": "U", "KeyType": "HASH"}],
            }
        ],
    ),
    table("Example_DeletedAccountsLock", "P", "S"),
    table("Example_Accounts_PhoneNumbers", "P", "S"),
    table("Example_Keys", "U", "B", "DK", "B"),
    table("Example_PQ_Paged_Keys", "U", "B", "D", "N"),
    table("Example_PushNotificationExperimentSamples", "N", "S", "AD", "B"),
    table("Example_EC_Signed_Pre_Keys", "U", "B", "D", "N"),
    table("Example_PQ_Last_Resort_Keys", "U", "B", "D", "N"),
    table(
        "Example_PhoneNumberIdentifiers",
        "P",
        "S",
        attr_defs=[("P", "S"), ("PNI", "B")],
        gsis=[
            {
                "IndexName": "pni_to_p",
                "KeySchema": [{"AttributeName": "PNI", "KeyType": "HASH"}],
            }
        ],
    ),
    table("Example_Accounts_PhoneNumberIdentifiers", "PNI", "B"),
    table("Example_IssuedReceipts", "A", "S"),
    table("Example_Messages", "H", "B", "S", "B"),
    table("Example_OnetimeDonations", "P", "S"),
    table("Example_Profiles", "U", "B", "V", "S"),
    table("Example_PushChallenge", "U", "B"),
    table("Example_RedeemedReceipts", "S", "B"),
    table("Example_RegistrationRecovery", "P", "S"),
    table("Example_RemoteConfig", "N", "S"),
    table("Example_ReportMessage", "H", "B"),
    table("Example_ScheduledJobs", "S", "S", "T", "B"),
    table(
        "Example_Subscriptions",
        "U",
        "B",
        attr_defs=[("U", "B"), ("PC", "B")],
        gsis=[
            {
                "IndexName": "pc_to_u",
                "KeySchema": [{"AttributeName": "PC", "KeyType": "HASH"}],
            }
        ],
    ),
    table("Example_Accounts_UsedLinkDeviceTokens", "H", "B"),
    table("Example_Accounts_Usernames", "N", "B"),
    table("Example_VerificationSessions", "K", "S"),
    table("Example_AppleDeviceChecks", "U", "B", "KID", "B"),
    table("Example_AppleDeviceCheckPublicKeys", "PK", "B"),
    table("Example_ClientPublicKeys", "U", "B"),
]


def wait_for_ready(timeout_seconds=60):
    deadline = time.time() + timeout_seconds
    last_error = None

    while time.time() < deadline:
      try:
        client.list_tables()
        return
      except Exception as exc:
        last_error = exc
        time.sleep(1)

    raise RuntimeError(f"DynamoDB Local not ready at {ENDPOINT}: {last_error}")


def table_exists(name):
    try:
        client.describe_table(TableName=name)
        return True
    except ClientError as exc:
        if exc.response["Error"]["Code"] == "ResourceNotFoundException":
            return False
        raise


def normalize_table_description(table_description):
    return {
        "AttributeDefinitions": sorted(
            (item["AttributeName"], item["AttributeType"])
            for item in table_description.get("AttributeDefinitions", [])
        ),
        "KeySchema": [
            (item["AttributeName"], item["KeyType"])
            for item in table_description.get("KeySchema", [])
        ],
        "GlobalSecondaryIndexes": sorted(
            (
                index["IndexName"],
                tuple((item["AttributeName"], item["KeyType"]) for item in index.get("KeySchema", [])),
                index.get("Projection", {}).get("ProjectionType", "KEYS_ONLY"),
            )
            for index in table_description.get("GlobalSecondaryIndexes", [])
        ),
    }


def normalize_expected(spec):
    return {
        "AttributeDefinitions": sorted(
            (item["AttributeName"], item["AttributeType"])
            for item in spec.get("AttributeDefinitions", [])
        ),
        "KeySchema": [
            (item["AttributeName"], item["KeyType"])
            for item in spec.get("KeySchema", [])
        ],
        "GlobalSecondaryIndexes": sorted(
            (
                index["IndexName"],
                tuple((item["AttributeName"], item["KeyType"]) for item in index.get("KeySchema", [])),
                index.get("Projection", {}).get("ProjectionType", "KEYS_ONLY"),
            )
            for index in spec.get("GlobalSecondaryIndexes", [])
        ),
    }


def wait_for_table_status(name, desired_status, timeout_seconds=60):
    deadline = time.time() + timeout_seconds

    while time.time() < deadline:
        try:
            status = client.describe_table(TableName=name)["Table"]["TableStatus"]
            if status == desired_status:
                return
        except ClientError as exc:
            if desired_status == "DELETED" and exc.response["Error"]["Code"] == "ResourceNotFoundException":
                return
            raise
        time.sleep(1)

    raise RuntimeError(f"Timed out waiting for {name} to reach {desired_status}")


def delete_table(name):
    client.delete_table(TableName=name)
    wait_for_table_status(name, "DELETED")


def create_table(spec):
    client.create_table(**spec)
    wait_for_table_status(spec["TableName"], "ACTIVE")


def ensure_table(spec):
    name = spec["TableName"]

    if not table_exists(name):
        print(f"  [create] {name}")
        create_table(spec)
        return

    current = client.describe_table(TableName=name)["Table"]
    if normalize_table_description(current) == normalize_expected(spec):
        print(f"  [ok]     {name}")
        return

    if not RECREATE_ON_MISMATCH:
        print(f"  [mismatch] {name} (set DYNAMODB_RECREATE_ON_MISMATCH=1 to repair)")
        return

    print(f"  [recreate] {name}")
    delete_table(name)
    create_table(spec)


def main():
    print(f"Waiting for DynamoDB Local at {ENDPOINT} ...")
    wait_for_ready()
    print("Connected.\n")
    print("Ensuring table schemas...")

    for spec in TABLES:
        ensure_table(spec)

    tables = sorted(client.list_tables()["TableNames"])
    print("\nCurrent tables:")
    for table_name in tables:
        print(f"  {table_name}")
    print(f"\nTotal: {len(tables)} tables")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
