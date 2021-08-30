# BOSSA
Biologically Oriented Sound Segregation Algorithm. The algorithm performs spatial sound segregation using spatially sensitive neurons based on the model by Fischer et al. [1].

This code accompanies the [biorXiv paper](https://www.biorxiv.org/content/biorxiv/early/2020/11/04/2020.11.04.368548.full.pdf) "A biologically oriented algorithm for spatial sound segregation"

DEMO.m gives an example on how to process a sound file

# Dependencies
The demo uses the Coordinate Response Measure (CRM) Corpus, by Bolia et al.[2]. Download the corpus [here](https://drive.google.com/drive/folders/1nFjwSCCHjhKkBhwG9LrblcXeiulUEJLX?usp=sharing) or [here](https://github.com/LABSN/expyfun-data/tree/master/crm).

See CRM_info.txt for more details on how to use the corpus. 

`CRM_3source_40pairs_20161122.mat` contains trios of CRM sentences that has no repeated key words. Compiled by Junzi Dong.

# References
[1] Fischer, B. J., Anderson, C. H. & Peña, J. L. Multiplicative auditory spatial receptive fields created by a hierarchy of population codes. PLoS One 4, 24–26 (2009).
doi: [10.1371/journal.pone.0008015](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0008015).

[2] Bolia, R. S., Nelson, W. T., Ericson, M. A., and Simpson, B. D. (2000). “A speech corpus for multitalker communications research,” J. Acoust. Soc. Am. 107, 1065–1066. Online Access Available at https://asa.scitation.org/doi/10.1121/1.428288.
