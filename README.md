> **Last updated:** 12th February 2026  
> **Version:** 1.1  
> **Authors:** Gianni TUERO  
> **Status:** In Progress (can be improved)  
> {.is-warning}

---

# Ascension

This repository is an overview of all the other subprojects of the Ascension project.

---

## Table of Contents

- [Ascension](#ascension)
  - [Table of Contents](#table-of-contents)
  - [Setup](#setup)
    - [Initial Installation](#initial-installation)
    - [If You Already Cloned the Repository](#if-you-already-cloned-the-repository)
    - [Updating All Submodules](#updating-all-submodules)

---

## Setup

This repository uses **git submodules** to organize the different components of the project. To properly configure the repository, you need to initialize and fetch all submodules recursively.

### Initial Installation

```bash
git clone --recurse-submodules https://github.com/Ascension-EIP/Ascension.git
```

### If You Already Cloned the Repository

```bash
git submodule update --init --recursive
```

### Updating All Submodules

When you do a `git pull`, it does not automatically update the submodules. To fetch the latest changes from all submodules:

```bash
git pull --recurse-submodules
```

Or alternatively:

```bash
git pull
git submodule update --remote --recursive
```
