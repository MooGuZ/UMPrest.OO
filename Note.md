# Note of Design

## AccessPoint
- **IMEPLEMENTATION**
	- package access: *push*, *pop*, *pull*, and *fetch*.
	- connectivity: *connect*, *disconnect*, *addlink*, *rmlink*, and *isolate*.
	- *send*, *compare*, and [*isempty*]
- **DESIGN**
	- ID System: automatically register/deregister an ID in construction/destruction.
	- [*packagercd*]: record packages only in method *send*.
	- *no*: series number in multiple access-point case.

## SimpleAP
- **IMPLEMENTATION**
	- constructor: OBJ = SIMPLEAP(PARENT[, CAPACITY])
- **DESIGN**
	- require [*parent*] to be a *Unit*
	- require [*cache*] to be a *Container*

## Reshaper
- contructed without argument referring to a **Vectorizer**, while constructed with one argument of <*shape*> representing target shape of samples.
- length of [*shapercd*] is set to 1 by default (**TODO**: method *recrtmode* need address this property)

## Data Size
- **Sample** is the fundamental unit dealed in the system. If data containing temporal axis, **sample** only conver spatial dimensions of it, while, its fundamental units is called as a **sequence**. Besides, **batch** is a collection of **sample** or **sequence** that feed to system at one time.

## Package
- **DESIGN**
  - constructors of PACKAGE class donnot include process of converting to GPU memory
  - standardize data shape in construction
### SizePackage
- **TEST**
  - **PASS** : Linear Transformation, Model in PHLSTM
