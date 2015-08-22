# Shortcuts

The [glucose.md](glucose.md) modelling includes more detail than we usually need, and less than we might want. We would usually be happy to leave the roles and some of the devices implicit, but we would like to have links to the protocols used.

NOTE: The code in the following examples has not been tested.


## Existing Work

Chris Mungall, Alan Ruttenberg, David Osumi-Sutherland, and collaborators have built a macro-expansion system for OWL that is used for shortcut relations in a number of OBO ontologies. These are two relevant papers, one on implementation and one on its use:

- [Taking shortcuts with OWL using safe macros](http://precedings.nature.com/documents/5292/version/2)
- [A strategy for building neuroanatomy ontologies](http://www.ncbi.nlm.nih.gov/pubmed/22402613)

The implementation is part of the OBO file format codebase, now included in the OWLAPI: [code directory](https://github.com/owlcs/owlapi/tree/version4/oboformat/src/main/java/org/obolibrary/macro).

This work could used for OBI, but first we should evaluate our specific requirements. This document lays out some ideas about what we want.


## Tables to Triples

In a database or spreadsheet we might represent the glucose experiment as follows. First we would have a table linking specimens to their subjects.

specimen          | protocol   | subject
------------------|------------|--------
blood specimen 1  | protocol 1 | mouse 1

Then we would have a table of assays and results.

assay           | protocol   | evaluant         | result | unit
----------------|------------|------------------|--------|------
analyte assay 1 | protocol 2 | blood specimen 1 | 1000   | mg/ml

In both of these tables we would also include an investigator, timestamp, and other information.

A simple translation of these tables to linked data would look like this:

    protocol 1
      type: protocol

    protocol 2
      type: protocol

    collection process 1
      type: collecting specimen from organism
      executes protocol: protocol 1
      has input subject: mouse 1
      has output specimen: blood specimen 1

    analyte assay 1
      type: assay
      executes protocol: protocol 2
      has evaluant: blood specimen 1
      has measured value: 1000
      has measured unit: mg/ml

This is a convenient "shape" to query with SPARQL, but a long way from the detailed modelling in [glucose.md](glucose.md).


## Expanding and Contracting

We could use SPARQL to expand the simplified modelling to detailed modelling, by associating a SPARQL Update query with each protocol.

NOTE: The follow code is not strictly SPARQL, but uses familiar labels, like the example in [glucose.md](glucose.md), and can be automatically translated to proper SPARQL.


### Expanding Protocol 1

The WHERE block corresponds to the simplified modelling of the collection process above. The INSERT block corresponds to the first part of the detailed modelling in [glucose.md](glucose.md). Many of the instances are anonymous (blank nodes). This might not be exactly the right level of detail for a given purpose, but it demonstrates the approach.

    INSERT {
      ?subject
        type: Mus musculus

      _:glucose-molecules
        type: glucose
        part of: ?specimen

      _:syringe
        type: syringe

      _:test-tube
        type: test tube

      ?collection
        has specified input: ?subject
        has specified input: _:syringe
        has specified input: _:test-tube
        has specified output: ?specimen

      ?specimen
        type: blood specimen
        located in: _:test-tube
    }
    WHERE {
      ?collection
        type: collecting specimen from organism
        executes protocol: protocol 1
        has subject: ?subject
        has specified output: ?specimen
    }


### Contracting Protocol 1

Similarly, we can start with the detailed modelling and extract the simplified modelling using SPARQL.

The WHERE block becomes the INSERT block, without change. The INSERT block becomes the WHERE block, replacing blank nodes with SPARQL variables (so `_:` becomes `?`). Because the expansion and contraction are syntactically so similar, we could specify just the expansion and automatically generate the contraction.

    INSERT {
      ?collection
        type: collecting specimen from organism
        executes protocol: protocol 1
        has subject: ?subject
        has specified output: ?specimen
    }
    WHERE {
      ?subject
        type: Mus musculus

      ?glucose-molecules
        type: glucose
        part of: ?specimen

      ?syringe
        type: syringe

      ?test-tube
        type: test tube

      ?collection
        has specified input: ?subject
        has specified input: ?syringe
        has specified input: ?test-tube
        has specified output: ?specimen

      ?specimen
        type: blood specimen
        located in: ?test-tube
    }


### Expanding Protocol 2

Likewise, we can expand the simple modelling into the second part of [glucose.md](glucose.md).

    INSERT {
      _:glucometer
        type: glucometer

      ?assay
        type: analye assay
        has specified input: ?specimen
        has specified input: _:glucometer
        has specified output: _:measurement-datum

      _:evaluant-role
        type: evaluant role
        inheres in: ?specimen
        realized in: ?assay

      _:analyte-role
        type: analyte role
        inheres in: ?glucose
        realized in: ?assay

      _:measurement-datum
        type: measurement datum
        has value specification: _:value-specification

      _:value-specification
        type: scalar value specification
        has specified value: ?value^^xsd:real
        has measurement unit label: ?unit
    }
    WHERE {
      ?assay
        type: assay
        executes protocol: protocol 2
        has evaluant: ?specimen
        has measured value: ?value
        has measured unit: ?unit

      ?specimen
        has part: ?glucose
    }


### Contracting Protocol 2

    INSERT {
      ?assay
        type: assay
        executes protocol: protocol 2
        has evaluant: ?specimen
        has measured value: ?value
        has measured unit: ?unit

      ?specimen
        has part: ?glucose
    }
    WHERE {
      ?glucometer
        type: glucometer

      ?assay
        type: analye assay
        has specified input: ?specimen
        has specified input: ?glucometer
        has specified output: ?measurement-datum

      ?evaluant-role
        type: evaluant role
        inheres in: ?specimen
        realized in: ?assay

      ?analyte-role
        type: analyte role
        inheres in: ?glucose
        realized in: ?assay

      ?measurement-datum
        type: measurement datum
        has value specification: ?value-specification

      ?value-specification
        type: scalar value specification
        has specified value: ?value^^xsd:real
        has measurement unit label: ?unit
    }


## Smaller Pieces

This approach requires specifying SPARQL Update queries for the expansion of every protocol. Can we just specify an expansion for every shortcut relation? If so, we could add this information to an annotation on the OWL Object Property 'has evaluant' (for example), as done for the macro-expansion system linked to above.


### Expand 'has evaluant'

In the WHERE clause we use a SPARQL property chain to restrict the target to an instance of a subclass of 'assay' -- the domain of 'has evaluant'. In the INSERT block we create an anonymous individual evaluant role, and link it.

    INSERT {
      ?assay
        has specified input: ?evaluant

      _:evaluant-role
        type: evaluant role
        inheres in: ?evaluant
        realized in: ?assay
    }
    WHERE {
      ?assay
        type / subClassOf+ assay
        has evaluant: ?evaluant
    }


### Contract 'has evaluant'

In the WHERE block we match assays that realize an evaluant role for some input, and assert 'has evaluant'.

    INSERT {
      ?assay
        has evaluant: ?evaluant
    }
    WHERE {
      ?assay
        type / subClassOf+ assay
        has specified input: ?evaluant

      ?evaluant-role
        type: evaluant role
        inheres in: ?evaluant
        realized in: ?assay
    }


### Expand 'has measured unit'

Expanding 'has measured value' seems similar...

    INSERT {
      ?assay
        has specified output: _:measurement-datum

      _:measurement-datum
        type: measurement datum
        has value specification: _:value-specification

      _:value-specification
        type: value specification
        has specified value: ?value
    }
    WHERE {
      ?assay
        type / subClassOf+ assay
        has measured value: ?value
    }


### Expand 'has measured unit'

Now we run into trouble. If an assay 'has measured unit' then its output is a measurement datum with a scalar value specification. If we adopt the same approach as in the previous example and expand both relations in parallel, then we fail to assert that it is the **same** measurement datum and value specification.

    INSERT {
      ?assay
        has specified output: _:measurement-datum

      _:measurement-datum
        type: measurement datum
        has value specification: _:value-specification

      _:value-specification
        type: scalar value specification
        has measurement unit label: ?unit
    }
    WHERE {
      ?assay
        type / subClassOf+ assay
        has measured unit: ?unit
    }

We can work around the problem in this specific case, but it raises a general problem with interactions between the expansions and contractions.

