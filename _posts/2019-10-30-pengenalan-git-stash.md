---
layout: post
title: "Pengenalan git stash"
date: 2019-10-30 11:00:00 +0700
categories: git, software-development
comments: true
published: true
---

Dalam software development biasanya kita mengenal tiga fase, yaitu *development*, *staging* dan *production*. Setelah *pull-request*, kita lakukan *merge* ke branch *develop*, satu-per-satu *commit* tadi kita *cherry-pick* ke *staging* dan dari *staging* kita lakukan *merge* ke master (*production*).

Masalah yang sering terjadi adalah *conflict* kode ketika melakukan *cherry-pick* pada *commit* yang banyak saat membuat branch *staging*.

Melakukan git stash adalah salah satu solusi atas masalah tersebut. Git stash adalah fitur di Git untuk menggabungkan banyak *commit* menjadi sebuah *commit* saja, sehingga dapat mengurangi *conflict* yang terjadi saat *cherry-picking*.

Mari kita coba praktekan.

```sh
$> git init
$(master)> echo 'first commit' >> hello.txt
$(master)> cat hello.text
first commit
$(master)> git add .
$(master)> git commit -m 'first commit'
$(master)> git log
commit 9c3cf0ad2fc3375aa306b2c002d00e37356bb7f6 (origin/master, master)
Author: philiplambok <philiplambok71@gmail.com>
Date:   Wed Oct 30 19:14:31 2019 +0700

    first commit
```

Dengan kode-kode diatas, kita membuat sebuah initial projek dengan satu kommit, sekarang kita coba implementasikan git-stashnya dengan membuat sebuah fitur baru(*branch* baru).

```sh
$(new-feature)> git checkout -b new-feature
$(new-feature)> echo 'second commit' >> hello.txt
$(new-feature)> git add .
$(new-feature)> git commit -m 'second commit'
$(new-feature)> git log
commit b502e9dbd99924e613d85c39255d7406b128d15e (HEAD -> new-feature2)
Author: philiplambok <philiplambok71@gmail.com>
Date:   Wed Oct 30 19:35:53 2019 +0700

    second commit
commit 9c3cf0ad2fc3375aa306b2c002d00e37356bb7f6 (origin/master, master)
Author: philiplambok <philiplambok71@gmail.com>
Date:   Wed Oct 30 19:14:31 2019 +0700

    first commit
$(new-feature)> echo 'third commit' >> hello.txt
$(new-feature)> git add .
$(new-feature)> git commit -m 'third commit'
$(new-feature)> git log
commit 3aca7971c0e77a671ccfc25a8e6ef39d40052cb3 (HEAD -> new-feature2)
Author: philiplambok <philiplambok71@gmail.com>
Date:   Wed Oct 30 19:37:21 2019 +0700

    third commit
commit b502e9dbd99924e613d85c39255d7406b128d15e
Author: philiplambok <philiplambok71@gmail.com>
Date:   Wed Oct 30 19:35:53 2019 +0700

    second commit

commit 9c3cf0ad2fc3375aa306b2c002d00e37356bb7f6 (origin/master, master)
Author: philiplambok <philiplambok71@gmail.com>
Date:   Wed Oct 30 19:14:31 2019 +0700

    first commit
```

Sekarang kita sudah punya dua *commit* di branch *new-feature*. Mari kita implementasikan git stash pada branch ini agar hanya ada satu *commit* saja.

```sh
$(new-feature)> git rebash -i HEAD~2
pick b502e9d second commit
squash 3aca797 third commit
------
# This is a combination of 2 commits.
  Squased commit
$(new-feature)> git log
commit d6562c011d4b30e8271eed39ddf113cd454fa4c6 (HEAD -> new-feature2)
Author: philiplambok <philiplambok71@gmail.com>
Date:   Wed Oct 30 19:35:53 2019 +0700

    Squased commit
commit 9c3cf0ad2fc3375aa306b2c002d00e37356bb7f6 (origin/master, master)
Author: philiplambok <philiplambok71@gmail.com>
Date:   Wed Oct 30 19:14:31 2019 +0700

    first commit
```

*Commit* berhasil di squash, sekarang *welcome to merge*. Dan untuk sekedar info `$> git rebash -i HEAD~2` artinya kita ingin menggabungkan 2 commit dari *HEAD*, yaitu pada kasus ini adalah *third commit* dan *second commit*.

Kira-kira itu saja tulisan kali ini, semoga dapat bermamfaat, *happy hacking~*.

