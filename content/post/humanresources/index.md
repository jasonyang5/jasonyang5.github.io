---
title: "The Investment Bank HR Problem" 
date: 2022-10-01T09:48:39-05:00
draft: false
tags: ["Research"]
categories: ["Economics"]
math: true
summary: Motivated by recent news and conversations from friends, I solve a very simplistic microeconomic model showing why banks over work analysts in good times and fire in bad. 
cover:
    image: "layoffs.png"
    alt: "Screenshot of Economist Article - Investment Banks are Sharpening the axe"
    caption: ""
    relative: false
---

## Motivation and Overview
Recently, multiple news sources reported that Goldman Sachs would start a material amount of layoffs right after a period of record deal-making, revenues, and (anecdotally) analyst overwork for investment banking as an industry. At first glance, this doesn't make much sense - how could it be beneficial to overwork employees and then lay them off? Why not hire more (or less) to begin with? In this post I work out a simple profit-max problem showing that 1) imperfect forecasting of future dealflow and 2) sticky hiring make it optimal to overwork analysts during good times and underwork (+ fire) them during bad.

In subsequent blog posts, I'll consider complications where there are Directors bringing in dealflow and Mid-Level (think Associate or VP) that manage analysts and make them scale better. 

## Basic Setup
Intuitively, the investment bank wants to choose hiring that maximizes expected revenues. Banks with a crystal ball would hire perfectly - unfortunately they can't. 

Mathematically, we say these are "constraints"
1. Banks are uncertain about next year's deaflow
2. Banks can only pick hires one year in advance (no re-neging/cancelling of offers)

Mathematically this is expressed as the following optimization problem

$$\max_{\ell_{t-1}} \mathbb{E}\left(\underbrace{r\min\left\( f\left(\ell_{t-1}\right),D_{t}\right\) }_{\text{Revenues}}-\underbrace{w\ell_{t-1}}_{\text{Wages Paid}}\right)$$

Where
1. \\(f(\ell)\\) is analyst productivity
2. \\(D_t\\) is the number of deals
3. \\(w\\) is wage
4. \\(r\\) is the revenue made by the bank per deal

Revenues is the more complicated term. Intuitively, if there are too many deals, \\(D_t > f(\ell_{t-1})\\), the firm could have hired more analysts to make more revenue. If there aren't enough deals, \\(D_t < f(\ell_{t-1})\\), the firm over hired and is wasting money on wages. That's why total revenues is the minimum of the two. 

\\(D_t\\) is not known ahead of time but the firm can guess. Essentially, I'm assuming that good times are likely to continue and bad times are too. That being said, there's still a nonzero chance that the times change. 

## Solution
Under reasonable assumptions, we get that the number of analysts hired looks like this:
$$\ell_{t-1}=\frac{r\cdot p_{\text{good}}}{w}$$


But remember - \\(p_\text{good}\\) will be high if we're in a high dealflow state and will be low if we are in a low dealflow state. 

Economically,
1. Analyst hiring follows the dealflow (economic) cycle. The firm will fire analysts when we move from good deal flow to bad deal flow because bad times are likely to continue (reducing \\(p_\text{good}\\))
2. The firm will hemorrage money in the low state, over hiring, in preparation for capturing more deal flow in the high state
3. Analysts are over-worked in the high deal flow state because there are much more deals than analysts can work on

## More Detail
I typed this up like I would a problem set from university [here](hr_problem_latex.pdf)