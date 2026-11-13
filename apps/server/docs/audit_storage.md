# Object Storage Replacement Audit

## RustFS vs Garage vs Ceph vs Silo

**Date:** September 2026
**Status:** Final assessment
**Current solution:** MinIO Community Edition
**Target:** Self-hosted S3-compatible object storage
**Workload:** Video and image storage
**Target scale:** ~1,000 users

---

# 1. Executive Summary

This audit evaluates four object-storage solutions as potential replacements for MinIO Community Edition:

* **RustFS**
* **Garage**
* **Ceph**
* **Silo**

The objective is to select a storage platform suitable for a production application storing primarily **videos and images**, with approximately **1,000 users**.

The evaluation focuses on:

* S3 compatibility
* Performance
* Reliability
* Data durability
* Security
* Scalability
* Operational complexity
* Backup and disaster recovery
* Migration effort
* Project maturity and maintainability
* Licensing
* Resource requirements

The current MinIO Community Edition is no longer a suitable long-term foundation because the upstream repository was archived on **April 25, 2026** and explicitly states that the project is no longer maintained.

The four candidates have significantly different architectures and operational models.

| Solution   | Architecture                 | Primary target                           |
| ---------- | ---------------------------- | ---------------------------------------- |
| **RustFS** | Distributed object storage   | S3 object storage with performance focus |
| **Garage** | Distributed object storage   | Self-hosted small/medium deployments     |
| **Ceph**   | Distributed storage platform | Large-scale infrastructure               |
| **Silo**   | MinIO fork                   | MinIO-compatible object storage          |

### Final selection

**Selected solution: RustFS**

RustFS provides the best overall fit for the target workload because it combines:

* S3-compatible object storage
* Distributed architecture
* Erasure coding
* Multi-node deployments
* Modern Rust implementation
* Strong performance objectives
* Object-storage-specific architecture
* A deployment model appropriate for the expected scale
* A more conventional Apache-2.0 licensing model than the AGPL alternatives
* A substantially smaller infrastructure scope than Ceph

RustFS is not selected because Rust automatically makes it secure or because it is newer.

In fact, its current security history requires explicit monitoring and disciplined upgrades. For example, RustFS has had high-severity authorization and object-storage security vulnerabilities during 2026.

The selection is based on the **overall fit of the architecture to the workload**, assuming the production PoC validates the required performance and recovery characteristics.

---

# 2. Requirements

## 2.1 Functional requirements

The storage platform must provide:

* S3-compatible API
* Bucket management
* Object upload
* Object download
* Object deletion
* Multipart uploads
* Range requests
* Presigned URLs
* Access control
* TLS
* Metrics
* Health checks
* Multi-node deployment
* Failure recovery

The application primarily stores:

* Images
* Videos
* Thumbnails
* Media metadata

---

# 3. Workload

The target environment is approximately:

```text
Users:                  ~1,000
Storage type:           Object storage
Primary data:           Video + images
Object sizes:           Small images → multi-GB videos
Access pattern:         Large sequential reads + writes
Protocol:               S3
Deployment:             Self-hosted
```

The workload is therefore primarily **large-object storage and high-bandwidth reads**, rather than a workload dominated by millions of tiny objects or extremely high transaction rates.

This distinction is important.

The storage system does not need to be the most scalable distributed-storage system ever built.

It needs to provide sufficient:

```text
capacity
+
throughput
+
availability
+
durability
+
operability
```

with sufficient headroom.

---

# 4. Evaluation Criteria

The candidates are evaluated using the following criteria.

| Category                           |   Weight |
| ---------------------------------- | -------: |
| Reliability & durability           |      20% |
| Security                           |      15% |
| Performance                        |      15% |
| Operational complexity             |      15% |
| S3 compatibility                   |      10% |
| Scalability                        |      10% |
| Backup & disaster recovery         |       5% |
| Project maturity & maintainability |       5% |
| Licensing                          |       5% |
| **Total**                          | **100%** |

These weights reflect the target workload rather than general storage-system capabilities.

---

# 5. Architecture Comparison

## 5.1 RustFS

RustFS is a distributed S3-compatible object-storage system written in Rust.

Its architecture uses distributed nodes and erasure coding for durability. The project describes itself as a high-performance distributed object store and supports IAM/STS and multi-tenant deployments.

Conceptually:

```text
                 S3 Clients
                     |
                     v
              ┌─────────────┐
              │   RustFS    │
              └──────┬──────┘
                     |
        ┌────────────┼────────────┐
        ↓            ↓            ↓
      Node 1       Node 2       Node 3
        |            |            |
      Disk          Disk         Disk
```

RustFS is therefore directly designed around the same abstraction required by the application:

```text
Application
    ↓
   S3
    ↓
Object Storage
```

This avoids introducing additional storage layers that are unnecessary for an object-only workload.

---

# 6. Garage

Garage is also a distributed object-storage system.

Its production documentation recommends at least three nodes for cluster operation and supports three-way replication across zones. It also provides mechanisms for storage layout, capacity allocation and geographic placement.

Garage's architecture is explicitly designed around distributed S3 storage.

It therefore satisfies the fundamental architectural requirement.

One notable operational characteristic is its separation between:

```text
metadata storage
+
object data storage
```

The documentation recommends SSD storage for metadata and discusses filesystem and database considerations for metadata durability.

This is relevant for production deployment because the metadata subsystem becomes an operational consideration in its own right.

---

# 7. Ceph

Ceph is fundamentally broader than an object-storage product.

Its architecture provides:

* Object storage
* Block storage
* Filesystem storage

S3 access is provided through the **Ceph Object Gateway (RGW)**.

Conceptually:

```text
                    Application
                         |
                        S3
                         |
                       RGW
                         |
                       RADOS
              ┌──────────┼──────────┐
              ↓          ↓          ↓
             OSD        OSD        OSD
              |          |          |
            Disk       Disk       Disk
```

This architecture provides an enormous scalability envelope.

However, it also means that the application is not deploying simply an object store.

It is deploying a distributed storage platform with multiple storage services and operational concepts.

This can be justified when an organization needs:

* S3
* Block storage
* CephFS
* Very large clusters
* Multiple storage consumers

It is less obvious that these additional capabilities provide value for an application whose requirement is primarily:

```text
S3
+
video
+
images
```

---

# 8. Silo

Silo is a community-maintained fork of MinIO.

It is therefore architecturally much closer to the existing deployment than the other candidates.

Silo explicitly preserves:

* S3 compatibility
* `MINIO_*` environment variables
* MinIO metrics
* MinIO headers
* MinIO routes
* `.minio.sys`
* MinIO storage format

The project states that the protocol and data remain unchanged while the delivery and product surfaces are renamed.

This makes Silo particularly attractive from a migration perspective.

It is effectively:

```text
Existing MinIO
      ↓
     Silo
```

rather than:

```text
Existing MinIO
      ↓
New storage architecture
```

---

# 9. S3 Compatibility

All four candidates provide an S3 interface.

| Feature        | RustFS | Garage | Ceph RGW | Silo |
| -------------- | ------ | ------ | -------- | ---- |
| PUT            | Yes    | Yes    | Yes      | Yes  |
| GET            | Yes    | Yes    | Yes      | Yes  |
| DELETE         | Yes    | Yes    | Yes      | Yes  |
| LIST           | Yes    | Yes    | Yes      | Yes  |
| Multipart      | Yes    | Yes    | Yes      | Yes  |
| Range requests | Yes    | Yes    | Yes      | Yes  |
| Presigned URLs | Yes    | Yes    | Yes      | Yes  |
| IAM / policies | Yes    | Yes    | Yes      | Yes  |
| TLS            | Yes    | Yes    | Yes      | Yes  |

For the application, this means that all four candidates can theoretically expose the required storage interface.

The important difference is therefore not basic S3 support.

The important differences are:

```text
compatibility depth
+
implementation behaviour
+
performance
+
operability
+
recovery
```

---

# 10. MinIO Migration

## Silo

Silo has the strongest migration compatibility.

The project explicitly maintains the MinIO storage format and compatibility interfaces. Existing `.minio.sys` data is supported without conversion.

Its migration tooling and service configuration are specifically designed to take over existing MinIO deployments. Recent release notes also describe a four-node MinIO-to-Silo migration test including data verification, rolling restart testing, fault injection and rollback rehearsal.

This is a major advantage.

---

## RustFS

RustFS provides MinIO/S3 compatibility, but migration should primarily be performed through the S3 API.

The migration path should therefore be:

```text
MinIO
  |
  | S3
  ↓
RustFS
```

rather than assuming that the existing MinIO filesystem can simply be attached to RustFS.

This creates additional migration work compared with Silo.

However, it also avoids long-term dependence on MinIO's internal storage format.

---

## Garage

Garage requires an S3-level migration.

```text
MinIO
  |
  | S3
  ↓
Garage
```

No MinIO filesystem compatibility should be assumed.

---

## Ceph

The migration is also S3-level:

```text
MinIO
  |
  | S3
  ↓
Ceph RGW
```

This is technically straightforward but requires migration of the complete object dataset.

---

# 11. Reliability and Durability

## RustFS

RustFS uses erasure coding to distribute object data across nodes and disks.

The important production tests are:

* Disk failure
* Node failure
* Multiple disk failures
* Network partition
* Rebuild
* Recovery
* Data verification

---

## Garage

Garage uses distributed replication.

Its documentation recommends three nodes and three-way replication as its safest and most available configuration. It also uses zones to distribute copies across physical locations.

This is a strong model for small-to-medium distributed deployments.

A notable operational consideration is the metadata database.

Garage's documentation warns about metadata durability considerations and recommends snapshots for LMDB metadata, particularly around unclean shutdowns.

This must be included in the disaster-recovery design.

---

## Ceph

Ceph has extensive distributed-storage mechanisms for data placement, redundancy and failure recovery.

Its RADOS layer is specifically designed for distributed storage and RGW provides the S3 interface above it.

Reliability is therefore not a concern at the architectural level.

The concern is operational complexity.

---

## Silo

Silo inherits MinIO's distributed storage architecture.

Its compatibility strategy is explicitly designed to preserve existing MinIO storage behaviour.

This reduces migration risk but also means that the deployment remains dependent on the MinIO-derived architecture.

---

# 12. Performance

Performance should be measured rather than inferred.

The relevant workload is:

```text
large objects
+
high-bandwidth GET
+
large uploads
+
concurrent clients
```

RustFS explicitly positions itself as a high-performance object-storage system, and its July 2026 beta release reported improvements over MinIO on PUT workloads while narrowing the GET gap. These are vendor benchmarks and therefore require independent validation.

The relevant benchmark is:

```text
RustFS
vs
Garage
vs
Ceph RGW
vs
Silo
```

using:

* identical hardware
* identical disks
* identical network
* identical object dataset
* identical concurrency

---

# 13. Performance Test Plan

## Large object upload

```text
1 GB
5 GB
10 GB
50 GB
```

Measure:

* MB/s
* latency
* CPU
* RAM
* network
* disk throughput

---

## Large object download

Same dataset.

Concurrency:

```text
1
10
50
100
250
500
1000
```

---

## Video streaming

Simulate HTTP range requests:

```text
100 users
250 users
500 users
1000 users
```

Measure:

* Time to first byte
* Range-request latency
* Aggregate throughput
* Failed requests
* CPU
* Network utilization

---

# 14. Security

Security must be evaluated independently from implementation language.

## RustFS

RustFS benefits from Rust's memory-safety properties, but memory safety does not eliminate application-level security vulnerabilities.

This is demonstrated by several RustFS advisories.

For example:

* CVE-2026-27607 involved missing validation for presigned POST policies and could permit unauthorized object writes.
* CVE-2026-73286 involved attacker-controlled HTTP headers influencing server-derived IAM condition keys.
* CVE-2026-73288 involved Object Lock protections being treated as absent under certain metadata-read failures.

These vulnerabilities do not indicate that RustFS is unsuitable.

They indicate that:

> RustFS must be operated with a strict upgrade and vulnerability-monitoring process.

The audit should therefore require:

* Pinned releases
* Automated vulnerability monitoring
* Security update procedure
* Regression testing
* No deployment of unreleased development versions

---

## Garage

Security evaluation must cover:

* S3 authentication
* Bucket policies
* TLS
* Administrative access
* Metadata security
* Dependencies
* Upgrade process

The project should be evaluated through its security advisories and source/dependency history.

---

## Ceph

Ceph has a mature security ecosystem and supports mechanisms including:

* S3 authentication
* IAM
* STS
* LDAP
* MFA
* OPA integration

through RGW.

Its larger ecosystem is an advantage for enterprise security operations.

---

## Silo

Silo has its own security process separate from upstream MinIO.

Its security policy states that Silo-specific vulnerabilities are handled by the Silo maintainers rather than MinIO.

Silo also publishes release artifacts with checksums, SBOMs, Sigstore-signed manifests and build attestations.

However, Silo remains a relatively new downstream project.

Its long-term maintenance must therefore be monitored.

---

# 15. Operational Complexity

## RustFS

Expected complexity:

**Medium**

A typical deployment consists primarily of:

```text
RustFS nodes
+
storage
+
network
+
monitoring
```

This maps directly to the application's requirements.

---

## Garage

Expected complexity:

**Low → Medium**

Garage has a relatively small operational footprint.

Its documentation provides explicit cluster deployment, node layout and zone configuration procedures.

The metadata subsystem requires additional operational attention.

---

## Ceph

Expected complexity:

**High**

The system contains substantially more distributed-storage infrastructure.

For an S3-only workload, this increases:

* Deployment complexity
* Monitoring requirements
* Troubleshooting complexity
* Upgrade complexity
* Recovery complexity
* Required operational knowledge

The complexity is justified when the additional storage capabilities are required.

---

## Silo

Expected complexity:

**Low → Medium**

Silo is particularly attractive for the existing infrastructure because its configuration and storage model are intentionally derived from MinIO.

The project even provides a service takeover mechanism where `silo.service` can supersede `minio.service` while reading existing MinIO configuration.

---

# 16. Scalability

## RustFS

RustFS is designed as a distributed object-storage system and supports multi-node deployments and erasure coding.

The target workload of approximately 1,000 users is therefore within the conceptual scope of the architecture.

---

## Garage

Garage is specifically oriented toward self-hosted small-to-medium deployments.

Its documentation recommends three or more nodes for production cluster deployment and supports distributing replicas across zones.

This makes it relevant to the target scale.

The remaining question is its performance and operational margin under the actual workload.

---

## Ceph

Ceph has the largest scalability envelope of the four.

It can scale far beyond the requirements of a 1,000-user application.

This is technically valuable but does not automatically make it the best choice.

---

## Silo

Silo retains the underlying MinIO architecture.

Its scalability characteristics are therefore largely inherited from the upstream architecture.

This is a positive factor for migration because there is less architectural change.

---

# 17. Resource Requirements

| Criterion          | RustFS              | Garage | Ceph        | Silo       |
| ------------------ | ------------------- | ------ | ----------- | ---------- |
| CPU overhead       | Expected low/medium | Low    | Medium/high | Low/medium |
| RAM footprint      | Medium              | Low    | High        | Medium     |
| Number of services | Low                 | Low    | High        | Low        |
| Operational nodes  | Low/medium          | Low    | Medium/high | Low/medium |
| Storage-only focus | Yes                 | Yes    | No          | Yes        |

These values should be validated experimentally before production deployment.

---

# 18. Backup and Disaster Recovery

None of the candidates should be treated as a complete backup solution merely because data is replicated.

The production design should be:

```text
                 Production
                    |
          ┌─────────┴─────────┐
          ↓                   ↓
     Object Storage       Independent Backup
          |                   |
       Cluster A           Cluster B
```

The backup system should be independent from the primary storage cluster.

Test:

* Accidental deletion
* Credential compromise
* Corrupted objects
* Complete node loss
* Complete cluster loss
* Disaster recovery

---

# 19. Licensing

| Project | License              |
| ------- | -------------------- |
| RustFS  | Apache-2.0           |
| Garage  | AGPLv3               |
| Ceph    | LGPL-based ecosystem |
| Silo    | AGPLv3               |

For an organization operating the storage infrastructure internally, all four can potentially be considered.

However, the legal implications of AGPL must be reviewed separately if the software is modified, redistributed, embedded or exposed as part of a service.

RustFS's Apache-2.0 license is operationally simpler from a permissive-licensing perspective.

---

# 20. Maintainability

## RustFS

Advantages:

* Modern Rust implementation
* Dedicated object-storage architecture
* Active development
* Distributed architecture
* Explicit security fixes

Risks:

* Younger project
* Smaller ecosystem than Ceph
* Current security history requires monitoring

---

## Garage

Advantages:

* Focused architecture
* Established project
* Simple deployment model
* Explicit small/medium self-hosting target

Risks:

* Smaller ecosystem
* More limited scope
* Metadata subsystem requires attention
* Less direct MinIO compatibility

---

## Ceph

Advantages:

* Very mature
* Large ecosystem
* Large-scale production usage
* Extensive capabilities

Risks:

* High operational complexity
* Larger learning curve
* More components
* Larger infrastructure footprint

---

## Silo

Advantages:

* Direct MinIO lineage
* Very high compatibility
* Minimal migration effort
* Existing MinIO knowledge remains applicable
* Active security maintenance

Risks:

* Community-maintained fork
* Long-term sustainability depends on maintainers
* AGPL
* Downstream divergence must be monitored

Silo explicitly states that it is an independent community-maintained fork and not affiliated with MinIO.

---

# 21. Comparison Matrix

| Criterion               | RustFS              | Garage               | Ceph           | Silo       |
| ----------------------- | ------------------- | -------------------- | -------------- | ---------- |
| S3                      | Excellent           | Excellent            | Excellent      | Excellent  |
| Video workload          | Excellent candidate | Good candidate       | Excellent      | Excellent  |
| Large objects           | Strong              | Strong               | Strong         | Strong     |
| Distributed             | Yes                 | Yes                  | Yes            | Yes        |
| Erasure coding          | Yes                 | Replication-oriented | Yes            | Yes        |
| Scalability             | High                | Medium               | Very high      | High       |
| Operational complexity  | Medium              | Low                  | High           | Low/Medium |
| Migration from MinIO    | Medium              | Medium               | Medium         | Very high  |
| MinIO compatibility     | High                | S3-level             | S3-level       | Very high  |
| Performance potential   | High                | High                 | High           | High       |
| Security maturity       | Developing          | Established          | Mature         | Developing |
| Resource requirements   | Medium              | Low                  | High           | Medium     |
| Ecosystem               | Growing             | Smaller              | Very large     | Small      |
| License                 | Apache-2.0          | AGPLv3               | LGPL ecosystem | AGPLv3     |
| Object-storage focus    | Yes                 | Yes                  | No             | Yes        |
| Long-term project risk  | Medium              | Medium               | Low            | Medium     |
| Fit for target workload | **High**            | **High**             | **Medium**     | **High**   |

---

# 22. Risk Analysis

## RustFS

### Main risks

1. Security vulnerabilities in a rapidly evolving project
2. Smaller ecosystem than Ceph
3. Less historical production data
4. Migration requires S3-level transfer rather than relying on MinIO disk compatibility

### Mitigation

* Pin production releases
* Automated CVE monitoring
* Security update process
* Full S3 compatibility test
* Failure testing
* Benchmark before deployment
* Maintain independent backup

---

## Garage

### Main risks

1. Smaller ecosystem
2. Different operational model from MinIO
3. Metadata durability requires explicit planning
4. Need to verify performance at target scale

### Mitigation

* Dedicated metadata storage
* Automated snapshots
* Three-node minimum production topology
* Performance PoC
* Failure/recovery tests

---

## Ceph

### Main risks

1. Operational complexity
2. Higher infrastructure requirements
3. More components to monitor
4. Potentially excessive scope for an object-only workload

### Mitigation

* Dedicated Ceph expertise
* cephadm-based deployment
* Comprehensive monitoring
* Formal operational procedures

---

## Silo

### Main risks

1. Dependence on a community fork
2. Long-term maintainer sustainability
3. AGPL
4. Downstream divergence

### Mitigation

* Pin releases
* Maintain rollback path
* Monitor upstream/downstream changes
* Maintain S3-level backup
* Regularly test migration to another S3 backend

---

# 23. Final Evaluation

The four candidates are technically viable, but they optimize for different objectives.

### Ceph

Ceph provides the largest infrastructure and scalability envelope.

However, its additional capabilities are not directly required by the target workload.

For an application primarily requiring object storage, introducing the complete Ceph ecosystem would add operational complexity without a clearly demonstrated requirement.

**Assessment: technically capable, but not the preferred architecture for this workload.**

---

### Garage

Garage provides a focused distributed object-storage architecture and has an explicit small-to-medium self-hosting target.

Its operational simplicity is attractive.

However, the project requires more validation around:

* large-scale video traffic
* sustained throughput
* metadata behaviour
* recovery characteristics
* performance headroom

**Assessment: credible alternative, particularly if operational simplicity is the dominant requirement.**

---

### Silo

Silo has the strongest migration story.

Its preservation of the MinIO protocol, configuration, metrics and on-disk format can significantly reduce migration risk.

However, adopting Silo also means making the organization dependent on a community-maintained MinIO fork.

The key question is therefore not technical compatibility.

It is long-term project sustainability.

**Assessment: excellent migration option and strong candidate, but introduces fork-maintenance dependency.**

---

### RustFS

RustFS provides a dedicated distributed object-storage architecture with:

* S3
* Erasure coding
* Multi-node deployment
* IAM/STS
* Rust implementation
* High-performance objectives
* Modern architecture

Its architecture is directly aligned with the workload.

Its current security history means it must be operated with disciplined release management and continuous security monitoring.

Its performance claims also require independent benchmarking rather than being accepted from vendor benchmarks.

---

# 24. Final Decision

## Selected solution: RustFS

**RustFS is the recommended replacement for MinIO for this workload.**

The main reason is architectural fit.

The target system needs:

```text
                    Application
                        |
                        S3
                        |
                    Object Store
                        |
             ┌──────────┼──────────┐
             ↓          ↓          ↓
          Storage    Storage    Storage
```

RustFS directly implements this model.

It provides distributed object storage without requiring the broader infrastructure of Ceph, while providing a more modern implementation than the existing MinIO deployment.

The selection is based on the following combination:

| Requirement           | RustFS                |
| --------------------- | --------------------- |
| S3 object storage     | Strong fit            |
| Video storage         | Strong fit            |
| Large objects         | Strong fit            |
| Distributed storage   | Yes                   |
| Data redundancy       | Erasure coding        |
| Horizontal scaling    | Yes                   |
| Operational footprint | Moderate              |
| Modern implementation | Rust                  |
| License               | Apache-2.0            |
| MinIO migration       | S3 migration required |
| Performance potential | High                  |
| Target scale          | Appropriate           |

The primary drawback is project maturity and security history.

That drawback does not eliminate RustFS, but it changes the production requirements:

```text
RustFS
  +
Pinned release
  +
CVE monitoring
  +
Automated backup
  +
Failure testing
  +
Performance testing
  +
Rollback procedure
```

---

# 25. Recommended Production Architecture

A production deployment should not use a single RustFS instance.

A distributed topology should be preferred.

Example:

```text
                    Application
                         |
                    Load Balancer
                         |
              ┌──────────┼──────────┐
              ↓          ↓          ↓
           RustFS 1   RustFS 2   RustFS 3
              |          |          |
              └──────────┼──────────┘
                         |
                 Distributed Storage
                         |
              ┌──────────┼──────────┐
              ↓          ↓          ↓
            Disk       Disk       Disk
```

The exact number of nodes and disks must be determined by:

* Required usable capacity
* Failure tolerance
* Network bandwidth
* Disk type
* Expected throughput
* Erasure-code configuration

---

# 26. Production Requirements

Before production deployment, the following gates must pass.

## Security

* [ ] Current supported RustFS release
* [ ] No known critical/high vulnerability without accepted mitigation
* [ ] TLS enabled
* [ ] Strong administrative credentials
* [ ] IAM policies reviewed
* [ ] Network segmentation
* [ ] Security monitoring configured

## Reliability

* [ ] Disk failure tested
* [ ] Node failure tested
* [ ] Recovery tested
* [ ] Rebuild tested
* [ ] Data integrity verified

## Performance

* [ ] Large upload benchmark passed
* [ ] Large download benchmark passed
* [ ] 1,000-user streaming scenario tested
* [ ] Range requests tested
* [ ] Performance headroom demonstrated

## Backup

* [ ] Independent backup configured
* [ ] Backup restoration tested
* [ ] Complete-cluster recovery tested

## Operations

* [ ] Monitoring configured
* [ ] Alerts configured
* [ ] Upgrade procedure documented
* [ ] Rollback procedure documented
* [ ] Capacity monitoring configured

---

# 27. Migration Strategy

Migration should be performed through the S3 API.

```text
                 Existing
                   MinIO
                     |
                     |
                 S3 transfer
                     |
                     ↓
                  RustFS
```

Recommended procedure:

### Phase 1

Deploy RustFS independently.

### Phase 2

Run S3 compatibility tests.

### Phase 3

Copy a representative dataset.

### Phase 4

Verify:

```text
object count
object size
checksums
metadata
content type
```

### Phase 5

Run the production workload against RustFS in staging.

### Phase 6

Perform failure testing.

### Phase 7

Perform backup/restore testing.

### Phase 8

Migrate production traffic.

### Phase 9

Keep MinIO available as rollback infrastructure until RustFS has been validated.

---

# 28. Final Recommendation

The recommended migration path is:

```text
MinIO Community
      |
      | S3 migration
      ↓
    RustFS
      |
      ├── Distributed storage
      ├── Erasure coding
      ├── S3 API
      ├── Monitoring
      └── Independent backup
```

### Decision

**RustFS**

### Alternatives

**Silo** should remain the primary fallback if migration compatibility with the existing MinIO deployment becomes the dominant concern.

**Garage** should remain the alternative if minimizing operational complexity becomes more important than maximizing performance and feature compatibility.

**Ceph** should be reconsidered only if the infrastructure eventually requires a broader distributed-storage platform covering object, block and filesystem workloads or substantially larger scale.

---

# 29. Important Caveat

The selection of RustFS is a **technical recommendation based on the evaluated architecture and current project state**, not a substitute for a production proof of concept.

Before deployment, the following three experiments are mandatory:

```text
1. Performance benchmark
2. Failure/recovery test
3. Full migration + rollback test
```

If RustFS fails any of these against the actual production requirements, the decision must be revisited.

The purpose of the PoC is therefore not to confirm RustFS.

It is to verify that the selected architecture actually satisfies the production requirements.

