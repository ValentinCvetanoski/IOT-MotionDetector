# Set the collection ID and S3 bucket name
$collectionId = "my-known-faces"
$bucketName = "iotmotionimagebucketallknown"
$folderName = "person1"

# Get the list of images in the specified folder
$images = aws s3 ls "s3://$bucketName/$folderName/" --recursive | ForEach-Object {
    # Extract just the image name (without the folder structure)
    $image = $_.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[-1]
    $imageName = $image.Split('/')[-1]  # Get the file name only
    $imageName
}

# Loop through each image and index it into Rekognition
foreach ($image in $images) {
    Write-Host "Indexing face in image: $image"

    $response = aws rekognition index-faces `
        --collection-id $collectionId `
        --image "S3Object={Bucket=$bucketName,Name=$folderName/$image}" `
        --external-image-id $image `
        --region us-east-1

    if ($response) {
        Write-Host "Successfully indexed face from $image"
    } else {
        Write-Host "Failed to index face from $image"
    }
}
