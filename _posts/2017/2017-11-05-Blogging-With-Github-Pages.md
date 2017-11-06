---
title: "Blogging with Github Pages"
description: "How I set up this blog in under 2 hours using Github Pages and how you can do it in minutes."
tags: [github]
---
# Blogging with Github Pages

How I set up this blog in under 2 hours using Github Pages and how you can do it in minutes.

## Previous Experience
Last time I tried to start a blog, I was trying to simultaneously learn Phoenix/Elixir.
As a result, I followed Brandon Richey's tutorial on how to build a blog engine.
I used Digital Ocean to host my site and Gatling so that I could just push to my server (Digital Ocean Droplet) and the site would automatically update but deploying was a huge pain point.
As a result I never actually got around to writing any blog posts and I had a terrible user interface.
So I decided it's time to start over again and this time I found the Github Pages documentation which was so much simpler.
I documented how I built that site [here](https://github.com/omegaphoenix/omegaphoenix.github.com/blob/v0.0.11/index.html)

## Steps
1. To follow this tutorial, you will need a Github account and optionally a DNS provider unless you want your domain to resolve to `<username>.github.io`.  When I was a student, I signed up for a free year with DNSimple using the Github Student Developer Pack.

2. Create a new project at Github named `<username>.github.com`.

3. Initialize a git repository.
```
git clone <repo url>
cd omegaphoenix.github.com
touch README.md
git add README.md
git commit -m "Add README"
git push -u origin master
```

4. (Optional: Skip this step if you don't have a DNS.) Add your CNAME to the CNAME file in your project's root directory.  (Make sure you only have one alias in this file or else it won't resolve correctly.)  If you want to set up another alias, you can do that with your DNS provider. (I added `www.jkleong.com` as a CNAME on DNSimple as well as `jkleong.com` as an alias.)
  * This was the longest step for me because I had used jkleong.com and had to wait for DNS propogation.
  * Since propogation can take up to 72 hours, I [flushed my local DNS cache] (https://www.namecheap.com/support/knowledgebase/article.aspx/397/2194/how-to-clear-the-local-dns-cache) and used the [Google Flush Cache tool] (https://developers.google.com/speed/public-dns/cache?hl=uk).
	* I had set up SSL encryption on my previous website so I also needed to clear my history (cookies and cache might have sufficed) before I got my new page to show up.
```
echo "<your-domain-goes-here>" > CNAME
git add CNAME
```

5. Write your first post at `_posts/${year}/${year}-${month}-${day}-${title}`.
```
echo "Test Post" > _posts/2017/2017-11-05-My-First-Blog-Post
git add _posts/2017/2017-11-05-My-First-Blog-Post
```

6. Set up an index file to display your posts. I used the [Jekyll Now](https://github.com/barryclark/jekyll-now) index.html file.
Copy [this file](https://github.com/barryclark/jekyll-now/blob/master/index.html) and save it to index.html in your project's root directory.

7. Add the index file and commit your changes and push.
```
git add index.html
git commit -am "Add CNAME, post, and index file"
git push origin master
```

8. Check out your site at `<username>.github.io` or `<username>.github.com`.  If you set up your DNS to alias to `<username>.github.io`, you should try clearing your history or open a private browsing window and then try to go to your webpage.  Look at step 3 foor how to flush the DNS cache.

## Follow-up
1. Choose a theme in your Github settings page.
2. Set up local deployment so that I wouldn't need to push every time I wanted to test my site: https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/
3. Try Hugo with Gitlab
