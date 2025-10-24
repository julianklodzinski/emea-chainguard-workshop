# 🔹 Why Join This Workshop
In this Workshop, you’ll learn how to use Chainguard Images — secure, minimal, and continuously verified container images — in a practical, hands-on way.

If anything like this sounds familar to you:
- “We want minimal and CVE-free images.”
- “We spend too much time chasing CVEs.”
- “Our customers require CVE-free software.”
- “We need to meet compliance targets.”
- "We have a golden Image programm"
- "We lost the overview about where all the images come from and what is in them"

# Chainguard Products
```
┌────────────────────────────────┐ ┌────────────────────────────────┐ ┌────────────────────────────────┐
│     Chainguard Containers      │ │     Chainguard Libraries       │ │         Chainguard VMs         │
│         1700+ Projects         │ │    Python Java JavaScript      │ │                                │
│     Distroless & CVE free      │ │ Maleware Mitigating & CVE free │ │        On-prem and Cloud       │
└────────────────────────────────┘ └────────────────────────────────┘ └────────────────────────────────┘
```

# ⚙️ Prework

Before joining the workshop, please make sure your environment is ready. This ensures you can fully participate in the hands-on exercises without interruptions.

## 🧰 Required Tooling
You’ll need the following tools installed and accessible from your terminal.
Follow the links for installation instructions:
| Tool         | Purpose                                            | Installation Link                                                                                   |
| ------------ | -------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **Chainctl** | CLI to interact with Chainguard services           | [Install Chainctl →](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/) |
| **Docker**   | Container runtime (any vendor/version is fine)     | [Docker Installation →](https://docs.docker.com/get-docker/)                                        |
| **Grype**    | Image vulnerability scanner                        | [Install Grype →](https://github.com/anchore/grype?tab=readme-ov-file#installation)                 |
| **git**      | To manage Code Repositories                        | [Install git →](https://git-scm.com/downloads)                                                      |

✅ Quick Check:
Run the following command to verify your setup:
```
chainctl version && docker version && grype version && git --version
```
All tools should return a version string.

## 🌐 Network Access
Make sure your system can reach the following endpoints, as they are required for the workshop labs:
- cgr.dev
- console.chainguard.dev
- data.chainguard.dev
- console-api.enforce.dev
- enforce.dev
- dl.enforce.dev
- issuer.enforce.dev
- apk.cgr.dev
- virtualapk.cgr.dev
- packages.cgr.dev
- packages.wolfi.dev

## 👥 Workshop Account Access
At the start of the session, you’ll receive an invite link granting access to your dedicated Workshop Organization in Chainguard. For authorization you need an account in one of the three providers:
- Google
- Gitlab
- Github

# 📚 Chainguard Libraries - 🧭 Workshop Step-by-Step Guide
```
┌────────────────────────────────┐
│     Chainguard Libraries       │
│    Python Java JavaScript      │
│ Maleware Mitigating & CVE free │
└────────────────────────────────┘
```

Ok you have spent a lot of time to work with our Containers. Now let's focus on Libraries :) When we talk about Libraries we talk about Python, Java and JavaScript Libraries you usually pull from Sources like PyPi, Maven or NPM. Our Libraries essentially do these things:
- Mitigate Maleware by building them from Source
- Providing Provenance so that you can check who and how they got built
- Patching and Backporting CVEs

So when we talk about CVEs the previous Part of the Workshop focused on the Image Level CVEs and security where Libraries focus on your Language based Vulnerabilities and maleware mitigation.

Let's get started :) 

## Understanding the Project structure

Let's start with checking out our Application first. For this:
1. Navigate to libraries folder and explore the content
2. Explore the app.py file and write down the dependencies you find there
3. Explore in the Statics folder the Webpage the app will service
4. Also compare the two Dockerfiles .vulnerable and .cgrimage and note down any differences
5. Check out the secret.cfg file
6. The *.toml files are kind of important as well as they will tell Python later where to download the dependencies from

## Building a vulnerable Image
Ok now let's build our Python Application with the public Python Image first.
```
docker build -f Dockerfile.public --no-cache . -t python:public
```
Now let's see if we get any CVEs
```
grype python:public
```
Ok, I guess we have plenty CVEs 🤨 you remember the dependency aiohttp in app.py? Let's have a look if we have any issues with this one.

And yes... we have some inside. You should find two High and several Medium Vulberabilities similar to this
```
NAME        INSTALLED  FIXED IN  TYPE    VULNERABILITY        SEVERITY  EPSS           RISK
aiohttp     3.9.1      3.9.2     python  GHSA-5h86-8mv2-jq9f  High      93.6% (99th)   62.7
aiohttp     3.9.1      3.9.4     python  GHSA-5m98-qgg9-wh84  High      0.3% (52nd)    0.2
```
Ok, before we go all crazy, let's check if we are exposed to these Vulnerabilities.
```
docker run --rm -it -p 8080:8080 python:public
```
And now let's do some simple checks
```
curl localhost:8080/static/index.html
```
This should give us the index.html back. Next let's see if we can get our Secret...
```
curl --path-as-is localhost:8080/static/../secret.cfg
```
If your output locks similar to this
```
[app]
config_key = value
secret = password123
```
You know you are impacted. Let's start fixing it.

## Fixing the Vulnerability with a secure Image
Our first attempt will be to fix this by switching to a more secure Image.
```
docker build -f Dockerfile.cgr --no-cache . -t python:cgr
```
Let's scan it
```
grype python:cgr
```
And we should see a drastically reduced amount of CVE.
But wait... 🤔 we still have the two high Vulnerabilities inside 🤔 I knew it! Chainguard Images are scams! Well... wait 🤣 Check out the TYPE of the Vulnerability - it's of type ```python```.
```
NAME        INSTALLED  FIXED IN  TYPE    VULNERABILITY        SEVERITY  EPSS           RISK   
aiohttp     3.9.1      3.9.2     python  GHSA-5h86-8mv2-jq9f  High      93.6% (99th)   62.7   
aiohttp     3.9.1      3.9.4     python  GHSA-5m98-qgg9-wh84  High      0.3% (52nd)    0.2    
```
Ok maybe we are safe now so let's try to exploit it.
```
docker run --rm -it -p 8080:8080 python:cgr
```
and of course
```
curl --path-as-is localhost:8080/static/../secret.cfg
```
outch... still there
```
[app]
config_key = value
secret = password123
```

### Summary
Now we have seen the following. We have built our Application with the Public Python Image and found plenty of CVEs and where able to exploit one high CVE.
Our first approach was to build with a secure Chainguard Image and this had really good effects on the CVEs itself but could not help us fix the CVE we are exposed to.
And this is pretty simple explained because the CVE we are facing is not on the OS level - it is on the Programming Language Level. And in order to fix this we need to fix the Python Library itself.

## Fixing the Vulnerability with a secure Image and Library
Let's build one more time our application. But this time we provide a ```uv.toml```file which tells Python to download the libraries from Chainguard.
```
docker build -f Dockerfile.cgr --no-cache --secret id=uv_toml,src=./uv.toml . -t python:cgr_patched
```
Let's scan this one
```
grype python:cgr_patched
```
Oh the High Vulnerabilities are gone now. And we can see a annotation behind the installed version ```+cgr.2``` indicating that this comes from us.
```
NAME        INSTALLED    FIXED IN  TYPE    VULNERABILITY        SEVERITY  EPSS           RISK   
aiohttp     3.9.1+cgr.2  3.9.4     python  GHSA-7gpw-8wmc-pm8g  Medium    0.7% (72nd)    0.4
```
Ok this seems good news. Let's test if we are still exposed or not.
```
docker run --rm -it -p 8080:8080 python:cgr_patched
```
and of course
```
curl --path-as-is localhost:8080/static/../secret.cfg
```
This should give you now a ```404: Not Found```

### 🥳You fixed the Python Vulnerability with Chainguard Libraries! 🎊

## Verifiying if a Library comes from Chainguard
That is a crucial part because you want to check if a Library comes from Chainguard or not. Provenance is a topic which becomes more and more important in every industry and is the foundation for true trust. Let's see if we can verify who built our Image and Libraries. Let's begin with the first Image we created:
```
chainver python:public
```
You should see that nothing in this image actually comes from us. Let's compare this to our last image.
```
chainver python:cgr_patched
```
Now you should see that most of what is inside actually got build by Chainguard.

# Chainguard - Your Safe Source for Open Source
