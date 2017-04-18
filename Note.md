# Note of Design

## AccessPoint
- **IMEPLEMENTATION**
	- package access: *push*, *pop*, *pull*, and *fetch*.
	- connectivity: *connect*, *disconnect*, *addlink*, *rmlink*, and *isolate*.
	- *send*, *compare*, and [*isempty*]
- **DESIGN**
	- ID System: automatically register/deregister an ID in construction/destruction.
	- [*packagercd*]: record packages only in method *send*.

## SimpleAP
- **IMPLEMENTATION**
	- constructor: OBJ = SIMPLEAP(PARENT[, CAPACITY])
- **DESIGN**
	- require [*parent*] to be a *Unit*
	- require [*cache*] to be a *Container*

## Reshaper
- contructed without argument referring to a **Vectorizer**, while constructed with one argument of <*shape*> representing target shape of samples.
- length of [*shapercd*] is set to 1 by default (**TODO**: method *recrtmode* need address this property)
