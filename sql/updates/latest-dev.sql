ALTER TABLE _timescaledb_catalog.telemetry_metadata RENAME TO metadata;
ALTER INDEX _timescaledb_catalog.telemetry_metadata_pkey RENAME TO metadata_pkey;
