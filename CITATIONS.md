# core-unit-bioinformatics/somaticsvcalling: Citations

# Citing this repository

If you are using the content of this repository in whole or in part for your own work,
please credit the Core Unit Bioinformatics in an appropriate form.

In general, please add this statement to the acknowledgments of your publication:

    This work was supported by the Core Unit Bioinformatics
    of the Medical Faculty of the Heinrich Heine University Düsseldorf.

Additionally, please follow the below instructions to obtain a citable reference
for your publication.

## Identifying the right source link

Each repository of the Core Unit Bioinformatics is assigned a persistent
identifier (PID) at some point (usually after the prototype stage). Please use
this PID to link to the repository. You always find the PID in the top-level
`pyproject.toml`. Depending on the type of repository (project, workflow, or
workflow template), the relevant PID is listed in the corresponding metadata
section:

```toml
# workflow repository
[cubi.workflow]
pid = "THE-PID"
```

```toml
# workflow template repository
[cubi.workflow.template]
pid = "THE-PID"
```

```toml
# project repository
[cubi.project]
pid = "THE-PID"
```

If a PID has not yet been assigned to the repository, please use the repository URL,
and, if time permits, contact the repository maintainer regarding assigning a PID
in the near future.

### 1. Release version

For release versions, please use the respective version string in addition to the source link,
i.e. ideally in combination with the PID, and integrate that information into your list
of references as appropriate.

Note that repositories of the type "project" may not contain a lot of code, and are thus
often not amenable to the usual "release cycle" following bug fixes, feature integrations and so on.
Hence, the "project" metadata do not contain a "version" key (as opposed to workflow and workflow
template repositories). See the next point if you encounter that situation.

### 2. Development (non-release) version

For development versions, please use the respective git commit hash in addtion to the source link,
i.e. ideally in combination with the PID, and integrate that information into your list
of references as appropriate. It is strongly recommended to only use git commits from the two
central branches `main` and `dev`.

If a "project" repository is lacking an explicit release version, please use the same strategy
to obtain a citable reference of the repository.


### 3. None of the above

Please get in touch and we'll find a solution for your case :-)

## Also, please additionally cite the used tools:

### [nf-core](https://pubmed.ncbi.nlm.nih.gov/32055031/)

> Ewels PA, Peltzer A, Fillinger S, Patel H, Alneberg J, Wilm A, Garcia MU, Di Tommaso P, Nahnsen S. The nf-core framework for community-curated bioinformatics pipelines. Nat Biotechnol. 2020 Mar;38(3):276-278. doi: 10.1038/s41587-020-0439-x. PubMed PMID: 32055031.

### [Nextflow](https://pubmed.ncbi.nlm.nih.gov/28398311/)

> Di Tommaso P, Chatzou M, Floden EW, Barja PP, Palumbo E, Notredame C. Nextflow enables reproducible computational workflows. Nat Biotechnol. 2017 Apr 11;35(4):316-319. doi: 10.1038/nbt.3820. PubMed PMID: 28398311.

### Pipeline tools

- [MultiQC](https://pubmed.ncbi.nlm.nih.gov/27312411/)

> Ewels P, Magnusson M, Lundin S, Käller M. MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics. 2016 Oct 1;32(19):3047-8. doi: 10.1093/bioinformatics/btw354. Epub 2016 Jun 16. PubMed PMID: 27312411; PubMed Central PMCID: PMC5039924.

### Software packaging/containerisation tools

- [Anaconda](https://anaconda.com)

  > Anaconda Software Distribution. Computer software. Vers. 2-2.4.0. Anaconda, Nov. 2016. Web.

- [Bioconda](https://pubmed.ncbi.nlm.nih.gov/29967506/)

  > Grüning B, Dale R, Sjödin A, Chapman BA, Rowe J, Tomkins-Tinch CH, Valieris R, Köster J; Bioconda Team. Bioconda: sustainable and comprehensive software distribution for the life sciences. Nat Methods. 2018 Jul;15(7):475-476. doi: 10.1038/s41592-018-0046-7. PubMed PMID: 29967506.

- [BioContainers](https://pubmed.ncbi.nlm.nih.gov/28379341/)

  > da Veiga Leprevost F, Grüning B, Aflitos SA, Röst HL, Uszkoreit J, Barsnes H, Vaudel M, Moreno P, Gatto L, Weber J, Bai M, Jimenez RC, Sachsenberg T, Pfeuffer J, Alvarez RV, Griss J, Nesvizhskii AI, Perez-Riverol Y. BioContainers: an open-source and community-driven framework for software standardization. Bioinformatics. 2017 Aug 15;33(16):2580-2582. doi: 10.1093/bioinformatics/btx192. PubMed PMID: 28379341; PubMed Central PMCID: PMC5870671.

- [Docker](https://dl.acm.org/doi/10.5555/2600239.2600241)

  > Merkel, D. (2014). Docker: lightweight linux containers for consistent development and deployment. Linux Journal, 2014(239), 2. doi: 10.5555/2600239.2600241.

- [Singularity](https://pubmed.ncbi.nlm.nih.gov/28494014/)

  > Kurtzer GM, Sochat V, Bauer MW. Singularity: Scientific containers for mobility of compute. PLoS One. 2017 May 11;12(5):e0177459. doi: 10.1371/journal.pone.0177459. eCollection 2017. PubMed PMID: 28494014; PubMed Central PMCID: PMC5426675.
