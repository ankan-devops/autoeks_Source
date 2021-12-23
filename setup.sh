#!/bin/bash
echo "Enter AWS_ACCESS_KEY _ID:"
read -r id
echo "Enter AWS_SECRET_ACCESS_KEY:"
read -r -s secr
echo "Enter region:"
read -r reg
aws configure set aws_access_key_id $id
aws configure set aws_secret_access_key $secr
aws configure set default.region $reg
aws configure set default.output json
echo "Enter a name for both EKS cluster & ECR (same name will be used in both):"
read -r cluster_n
echo "Enter node type (ex: t3.medium/m5.large):"
read -r no
echo "Enter node volume size:"
read -r si
aws configure list
aws sts get-caller-identity
aws ecr create-repository --repository-name $cluster_n
sleep 5
repoc=$(aws ecr describe-repositories --query repositories[0].repositoryUri)
repoc=$(echo $repoc | tr -d '"')
repo=$(echo $repoc | cut -d "/" -f 1)
sed -i "s|image: z|image: ${repoc}|g" /auto_eks/deployment.yaml
sed -i "s|REPO=|REPO=${repo}|g" /auto_eks/bitbucket-pipelines.yml
sed -i "s|CLUSTER_N=|CLUSTER_N=${cluster_n}|g" /auto_eks/bitbucket-pipelines.yml
sed -i "s|AWS_REGION=|AWS_REGION=${reg}|g" /auto_eks/bitbucket-pipelines.yml
sed -i "s|CLUSTER_N:|CLUSTER_N: ${cluster_n}|g" /auto_eks/.github/workflows/main.yml
sed -i "s|awsregion:|awsregion: ${reg}|g" /auto_eks/.github/workflows/main.yml
eksctl create cluster -n $cluster_n -r $reg --instance-types $no --node-volume-size $si --kubeconfig=~/.kube/config
echo "Enter the bitbucket/github repository:"
read -r url
echo "Enter the Username:"
read -r usr
echo "Enter the Password:"
read -r -s pass
touch ~/.git-credentials
cd /auto_eks
git init
git config --global user.email "abcdef@yahooo.com"
git config --global user.name "me"
git add .
if [[ $url == *"bitbucket"* ]]; then
	echo "https://${usr}:${pass}@bitbucket.org" > ~/.git-credentials
	git rm -r --cached .github
else
	echo "https://${usr}:${pass}@github.com" > ~/.git-credentials
	git rm --cached bitbucket-pipelines.yml
fi
git commit -m "first_time"
git config --global credential.helper store
git push $url master -f
cd /abc
git init
git clone $url autoeks
