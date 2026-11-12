#!/usr/bin/env node
import { existsSync } from "node:fs";
import path from "node:path";
import postgres from "postgres";
import { drizzle } from "drizzle-orm/postgres-js";
import { migrate } from "drizzle-orm/postgres-js/migrator";

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error("DATABASE_URL is required to run migrations.");
  process.exit(1);
}

const migrationsFolder =
  process.env.MIGRATIONS_FOLDER || path.join(process.cwd(), "db", "migrations");

if (!existsSync(path.join(migrationsFolder, "meta", "_journal.json"))) {
  console.error(`No migration journal found in ${migrationsFolder}.`);
  process.exit(1);
}

const client = postgres(databaseUrl, { max: 1, onnotice: () => {} });

try {
  // Serialize migrations across replicas with a session-level advisory lock.
  await client.unsafe(
    "SELECT pg_advisory_lock(hashtext('pagescms:migrations')::bigint)",
  );
  await migrate(drizzle(client), { migrationsFolder });
  console.log("Database migrations are up to date.");
} finally {
  try {
    await client.unsafe(
      "SELECT pg_advisory_unlock(hashtext('pagescms:migrations')::bigint)",
    );
  } finally {
    await client.end({ timeout: 5 });
  }
}
