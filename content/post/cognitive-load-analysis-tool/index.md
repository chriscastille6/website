---
title: "Cognitively Loaded?"
authors:
  - admin
date: "2024-12-19T00:00:00Z"
doi: ""
publishDate: "2024-12-19T00:00:00Z"
publication_types: ["0"]
publication: ""
publication_short: ""
abstract: ""
summary: ""
tags:
  - Research Methods
  - Cognitive Load
  - Text Analysis
  - R Programming
  - Open Science
  - Experimental Design
  - Psycholinguistics
featured: true
projects: []
slides: ""

url_pdf: ""
url_code: ""
url_dataset: ""
url_poster: ""
url_project: ""
url_slides: ""
url_source: ""
url_video: ""
url_app: "https://christopher-m-castille.shinyapps.io/cognitive-load-analysis/"

image:
  caption: "Cognitive Load Analysis Tool Interface"
  focal_point: "Center"
  preview_only: false

---

Recently, a colleague asked me to review some experimental stimuli for a study. The issue at hand was how cognitively loaded (i.e., how mentally demanding or effortful) the materials were, and whether the stimuli might unintentionally be a confound in the study by taxing participants’ working memory or attentional resources. In lay terms, complex stuff is much easier to read if you know big fancy words and are not initimidated by trying to understand them. If you don't understand the big fancy words or find them intimidating, you may make less optimal judgments.

I don’t formally study cognitive load but am familiar with the literature. Still, I fired up Consensus.ai for a quick, systematic review of the literature. The platform identified 1,051 papers, of which 592 were screened, 379 were deemed eligible, and the top 50 most relevant studies were ultimately included. These studies represented a range of designs, including psycholinguistic experiments, dual-task paradigms, EEG and fMRI studies, keystroke logging, recall tasks, and self-report/subjective measures of effort. [The full Consensus.ai report is available here](/uploads/Consensus%20Report.pdf).

Across these studies, the evidence was consistent: increased linguistic complexity (longer sentences, abstract vocabulary, complex syntax) elevated cognitive load, as shown in slower response times, higher self-reported effort, and physiological indicators such as pupil dilation and EEG theta power (Cohen et al., 2021; Castro-Meneses et al., 2019; Just et al., 1996; Vogelzang et al., 2020). Importantly, the effects were not uniform. Some studies found that complexity primarily affected speed and effort, while others documented reductions in response validity, particularly in participants with lower working memory, lower language proficiency, or higher anxiety (Révész et al., 2015; Güvendir & Uzun, 2023).

So far, no surprise, but it got me thinking about mission statements. I talk about the importance of mission statements in my HR classes, as well as how designing them maygo off the rails. Mission statements are often aspirational, but when written in overly complex or jargon-laden language - often by a well-intended committee - they risk introducing unnecessary cognitive load for the very audiences they are meant to inspire—students, faculty, alumni, and community partners.

Consider Dan Heath's take on mission statements "[How to Write a Mission Statement That Doesn't Suck](https://www.fastcompany.com/1404951/how-write-mission-statement-doesnt-suck-video)" (Fast Company, 2010). Heath provides a perfect example of cognitive load confounds in action. He illustrates how a pizza parlor's mission statement evolved through committee revisions:

**Condition A (Original Mission for a Pizza Parlor):**  
> "Our mission is to serve the tastiest damn pizza in Wake County."

**Condition B (Committee-Revised Mission):**
> "Our mission is to present with integrity the highest-quality entertainment solutions to families."

Heath did not talk about cognitive load (why would he as it kinda gets in the way of the point he's rightly making). That said, I was curious to analyze these conditions using a web tool I created (with the help of Cursor) to measure the cognitive load of text extractions. **The app is freely available at: [cognitive-load-analysis.shinyapps.io](https://christopher-m-castille.shinyapps.io/cognitive-load-analysis/)**. The tool incorporates multiple validated readability indices (Flesch, Gunning Fog, SMOG, etc.) and cognitive complexity measures based on sentence length, word length, and overall readability scores. Not surprisingly, the cognitive load metrics revealed differences that you would expect: the committee-revised mission statement was more cognitively loaded, containing more abstract terms "entertainment solutions" versus concrete "pizza," and corporate jargon ("present with integrity," "highest-quality") versus plain language ("tastiest damn"). More specific details are below. 

- **Flesch Score Gap:** 63.5 points (the committee version is rated "very difficult" to read compared to the original, which is "fairly easy" to read)
- **Word Count Difference:** Only 1 word (14 vs 13), yet vastly different complexity. The words are longer in the revised mission statement.
- **Cognitive Load Gap:** 19.7 points (basically the commitee version requires more cognitive processing than the original mission statement)

In prioritizing sounding professional over being understood, a well-intended committee makes it harder for their employees to get behind the company's mission. In other words, "entertainment solutions" should be swapped for "tastiest damn pizza" (or something close to it – like 'darn pizza')!!!

## References

Castro-Meneses, L. J., Kruger, J. L., & Doherty, S. (2019). Validating theta power as an objective measure of cognitive load in educational video. *Educational Technology Research and Development*, *68*(1), 181-202. https://doi.org/10.1007/s11423-019-09681-4

Cohen, M. L., Boulton, A., Lanzi, A., Sutherland, E., & Pompon, R. H. (2021). Psycholinguistic features, design attributes, and respondent-reported cognition predict response time to patient-reported outcome measure items. *Quality of Life Research*, *30*(6), 1693-1704. https://doi.org/10.1007/s11136-021-02778-5

Güvendir, E., & Uzun, K. (2023). L2 writing anxiety, working memory, and task complexity in L2 written performance. *Journal of Second Language Writing*, *62*, Article 101016. https://doi.org/10.1016/j.jslw.2023.101016

Heath, D. (2010, February 24). How to write a mission statement that doesn't suck [Video]. *Fast Company*. https://www.fastcompany.com/1404951/how-write-mission-statement-doesnt-suck-video

Just, M. A., Carpenter, P. A., Keller, T. A., Eddy, W. F., & Thulborn, K. R. (1996). Brain activation modulated by sentence comprehension. *Science*, *274*(5284), 114-116. https://doi.org/10.1126/science.274.5284.114

Vogelzang, M., Thiel, C., Rosemann, S., Rieger, J., & Ruigendijk, E. (2020). Neural mechanisms underlying the processing of complex sentences: An fMRI study. *Neurobiology of Language*, *1*, 226-248. https://doi.org/10.1162/nol_a_00011

---

*This work represents a collaboration between traditional psycholinguistic research methods and modern AI-assisted analysis, motivated by practical research needs and grounded in established cognitive load theory.*
