# Mobile Developer Coding Challenge

Please read the instructions below carefully before starting the coding challenge.

Once submitted, the mobile team will review your work and get back to you as soon as possible.

## The Goal

You will be building a simple two-screen podcasts app. A basic mockup is provided below:

[![](https://i.imgur.com/yi8w1s8.png)](https://i.imgur.com/yi8w1s8.png)

#### Screen 1

- [ ] Show a list of podcasts using the endpoint provided below.
- [ ] Each list item should show the podcast thumbnail, title, and publisher name.
- [ ] Leave some space for the "Favourited" label (refer to the second podcast in the list in the mockup above).
- [ ] Show the Favourited label only if the podcast has been favourited, otherwise hide the label.

#### Screen 2

- [ ] Tapping on a list item from Screen 1 should bring you to Screen 2.
- [ ] On Screen 2, show the podcast's title, publisher name, thumbnail, and description.
- [ ] Add a Favourite button.
- [ ] The Favourite button should have two states: Favourite and Favourited.
- [ ] When tapping the Favourite button, the label should change to Favourited, and vice-versa.

## Details

- [ ] Create a new repository to work in. Do <ins>**NOT**</ins> fork this repository.
- [ ] Must be written in Kotlin and use Jetpack Compose for Android applicants, and Objective-C or Swift for iOS applicants. For iOS applicants, please use UIKit.
- [ ] For the API, use data provided by Listen Notes:
	 - [ ] Use the following endpoint to fetch podcast data: https://www.listennotes.com/api/docs/?lang=kotlin&test=1#get-api-v2-best_podcasts
	 - [ ] No API key required, you can simply use the mock server to fetch test data. [More information here](https://www.listennotes.help/article/48-how-to-test-the-podcast-api-without-an-api-key "More information here").
- [ ] Focus on implementing the app in portrait orientation only.
- [ ] The list should support pagination, loading 10 items at a time.
- [ ] Favourite state should be persistent.

## The Evaluation

Your code will be evaluated based on the following criteria:

- [ ] The code should compile.
- [ ] No crashes, bugs, or compiler warnings.
- [ ] App operates as outlined above.
- [ ] Conforms to modern development principles.
- [ ] Code is easy to understand. Bonus points for documentation.
- [ ] Commit history is consistent, easy to follow and understand.
