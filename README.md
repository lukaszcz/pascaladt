PascalAdt is a library of data structures and algorithms for Free
Pascal and Delphi, inspired by the C++ STL library. It offers a wide
variety of data structures including lists, queues, double-ended
queues, binary trees, binary search trees, AVL trees, 2-3-trees, splay
trees and hash tables.

Features
--------
* STL-like class hierarchies of containers, iterators and functors.
* Automatic memory management for iterators.
* Dynamic array containers.
* Linked lists: singly linked, doubly linked and xor linked lists.
* Double-ended queues: circular and segmented.
* Search trees: AVL trees, splay trees, 2-3-trees.
* Hash tables: open and closed.
* Priority queues: binomial heaps.
* Sorting algorithms: quick sort, merge sort, shell sort, insertion sort.
* Selection algorithms: Hoare, Blum-Floyd-Pratt-Rivest-Tarjan.
* String algorithms: Knuth-Morris-Pratt, Boyer-Moore, Karp-Miller-Rosenberg.
* Sequence algorithms: binary search, interpolation seach, partition,
  merge, random shuffle, etc.

Requirements
------------
* Linux (should work on other systems, but the installation and
  compilation scripts might need adjusting).
* [Free Pascal](https://www.freepascal.org)

Installation and usage
----------------------
* Compilation: `make`
* Tests: `make test`
* Installation `make install`

Documentation
-------------

See [docsrc/tutorial.txt](docsrc/tutorial.txt) and [demo/customer/customer.pas](demo/customer/customer.pas).

Copyright and license
---------------------

Copyright (C) 2004-2021 Lukasz Czajka

Distributed under LGPL 2.1, see [LICENSE](LICENSE).
