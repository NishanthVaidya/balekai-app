#!/bin/bash
echo "🔄 Restoring backend changes..."
cp -r src/* ../src/
cp -r resources/* ../src/main/resources/
cp Dockerfile* ../
cp deploy-to-aws.sh ../
cp pom.xml ../
echo "✅ Backend changes restored!"
