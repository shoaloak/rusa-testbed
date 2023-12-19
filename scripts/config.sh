#!/usr/bin/env bash

# Full path prefix for the target classes
readonly TARGET_PREFIX="org.springframework.samples.petclinic.repository.jdbc."

# Associative array (dictionary) of vulnerabilities
declare -A TARGETS
readonly TARGET_KEYS=(
    "vuln1"
    "vuln2"
    "vuln3"
    "vuln4"
    "vuln5"
    "vuln6"
    "vuln7")

# GET /vets/{vetId}
TARGETS["vuln1"]="JdbcVetRepositoryImpl:vulnFindById"
# GET /specialties/{specialtyId}
TARGETS["vuln2"]="JdbcSpecialtyRepositoryImpl:vulnFindById"
# POST /vets
TARGETS["vuln3"]="JdbcVetRepositoryImpl:vulnSave"
# POST /owners
TARGETS["vuln4"]="JdbcOwnerRepositoryImpl:vulnStoreNewOwner"
TARGETS["vuln5"]="JdbcOwnerRepositoryImpl:vulnUpdateExistingOwner"
# PUT /owners/{ownerId}
TARGETS["vuln6"]="JdbcOwnerRepositoryImpl:vulnStoreNewOwner"
TARGETS["vuln7"]="JdbcOwnerRepositoryImpl:vulnUpdateExistingOwner"

function print_line {
    printf '%*s\n' 80 '' | tr ' ' '-'
}