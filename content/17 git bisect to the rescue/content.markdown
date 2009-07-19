An interesting feature in [Git](http://git.or.cz/) I came across the other day is the bisect command.

__"Find the change that introduced a bug by binary search"__

Certainly sounds intriguing, turns out it can be quite useful.

The motivation behind bisect is to help you find out when a bug was introduced into the source base, by marking a known good and bad point within the source, and examining commits in between those points following a binary search algorithm (ie. eliminating half of the possible commits each successive iteration).

Linux developers use it to track down issues in the kernel spread across hundreds if not thousands of commits.

Lets see an example, suppose we have a project with the following (annotated) log:

  commit bdf6fe9cd7c929487ffb6830b01a105836807f50
  Author: Marcus Crafter <crafterm@redartisan.com>
  Date:   Fri Mar 21 00:29:38 2008 +1100

      Added change 10       (version 2.0 aka HEAD)

  commit af4331699b1ecfc39f077149801d80e5d83ab5fe
  Author: Marcus Crafter <crafterm@redartisan.com>
  Date:   Fri Mar 21 00:29:38 2008 +1100

      Added change 9

  commit 9235af336946661c9c935c6f00a0b8590447dd6e
  Author: Marcus Crafter <crafterm@redartisan.com>
  Date:   Fri Mar 21 00:29:38 2008 +1100

      Added change 8  

  commit 25718d202ee9b16a3d661d46a9d4dac5ff80ab52
  Author: Marcus Crafter <crafterm@redartisan.com>
  Date:   Fri Mar 21 00:29:38 2008 +1100

      Added change 7
  
  commit af4932de08721a333a1c0c51d130c9d006f0bf61
  Author: Marcus Crafter <crafterm@redartisan.com>
  Date:   Fri Mar 21 00:29:38 2008 +1100

      Added change 6      (change introduced here)
  
  .....
  
  commit 463a5d5bd180e6b2d0eedaeb5227aeb357ca7827
  Author: Marcus Crafter <crafterm@redartisan.com>
  Date:   Fri Mar 21 00:29:38 2008 +1100

      Added change 1                 (version 1.0)


The history indicates 2 releases of the software package annotated via parenthesis.

Post release 2.0 lets say a defect is reported (for the reader we've flagged change 6 as the culprit, but lets pretend we don't know this for the moment). The information reported is that the feature used to work in version 1.0, but it's broken in version 2.0, but no one has any idea where.

So how can git help us track down what happened?

Using git bisect, we can do the following:

  $> git bisect start
  $> git bisect good version_1_0
  $> git bisect bad
  Bisecting: 4 revisions left to test after this
  [388ec2c43dcccb710fd9e636c3ecf28ca2b42709] Added change 5

We've told git that the tag _version\_1\_0_ (ie. change 1) was the last known point when the issue didn't occur, and that HEAD (ie. _version_2_0_) still has the issue. Given this information git takes these two known boundaries, and has chosen a midway point for us to inspect - change 5, which is half way between changes 1 and 10. 

If the defect is present in this revision, it was introduced in this commit or beforehand (eliminating the need to check commits 6-10 to see when the issue first appeared), if the defect isn't present, then it was introduced after (eliminating the need to check commits 1-5). Either way, we eliminate the need to check half the field of commits.

We test the software at change 5 and discover that the issue isn't present, so we tell git this particular change is good:

  $> git bisect good
  Bisecting: 2 revisions left to test after this
  [25718d202ee9b16a3d661d46a9d4dac5ff80ab52] Added change 7

git now fast forwards to change 7, which is midway between 5 and 10. We repeat the process again. Here things become interesting, after testing the software we find the defect has appeared - somewhere between 5 and 7, in this case a range of only 3 commits. We inform git that this point in the history is broken:

  $> git bisect bad
  Bisecting: 0 revisions left to test after this
  [af4932de08721a333a1c0c51d130c9d006f0bf61] Added change 6

Now the result is obvious. If change 6 is broken then change 6 has introduced the issue (we found out above that change 5 was good). If change 6 is good, then change 7 must have introduced the issue. Testing finds out that 6 is bad, yielding it as the commit that first exhibited the issue:

  $ git bisect bad
  af4932de08721a333a1c0c51d130c9d006f0bf61 is first bad commit
  commit af4932de08721a333a1c0c51d130c9d006f0bf61
  Author: Marcus Crafter <crafterm@redartisan.com>
  Date:   Fri Mar 21 00:29:38 2008 +1100

      Added change 6

  :100644 100644 bb009e53210caf5bd64c46c9299a1c315e393c59 17d7ba157d12c79dd6337f091491e542f49b2c14 M	README

and git tells us some more information about it. Now we can take a closer look at the commit details and see what happened to correct it.
  
Once we're done we can:
  
  $> git bisect reset && git checkout master
  
to continue development since the bisect takes place on a separate branch not to interfere with any other work you were previously doing.

Due to the nature of bisecting the commit space by binary search, searching across large ranges of commits can really be eased.
