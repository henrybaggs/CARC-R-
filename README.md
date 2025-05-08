# CARC-R-
Repo for jus tthe R code that went into the 2025 GPHY484R CARC project.

This is seperate from the rest of the group as that repo is not public and thus it cannot be displayed on my profile, but I still want my contributions to this project to be visible.

This repo contains several scripts that filter a planet sataset to the boundaries of CARC farm and creates a series of NDVI images, creates a GIF of said images, creates a shiny R app that allows you to click through these images at whatever dates you want, and finally sets up the tiffs in a way where they can be worked within Arc pro to make a time-aware mosaic.
 
Unfortunately, the "full_set" RDS is bigger than is natively supported by github and as such cant be stored here.
Also you'd want to use your own imagery anyways
To get around this, you must generate the "full_set" RDS using the NDVI_anim script, which requires a planet imagery dataset. You can do this locally if you have the storage or load this script into tempest and add planet data to your account and subsequently this project using globus. From there you can create and download the "full_set" rds and work with it locally. This is unfortunately necessary, as the gifski package used to create the gif product does not function in tempest. My apologies. 
