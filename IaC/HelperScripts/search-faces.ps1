$bucketName = "iotmotionimagebucketall"
$region = "us-east-1"
$collectionId = "my-known-faces"

# List all objects in the S3 bucket
$objects = aws s3api list-objects --bucket $bucketName --query "Contents[].Key" --region $region | ConvertFrom-Json

# Loop through each object and perform face search
foreach ($object in $objects) {
    Write-Host "Processing image: $object"

    $result = aws rekognition search-faces-by-image `
        --collection-id $collectionId `
        --image "S3Object={Bucket=$bucketName,Name=$object}" `
        --region $region | ConvertFrom-Json

    if ($result.FaceMatches) {
        Write-Host "Match found for $object"
        $result.FaceMatches | ForEach-Object {
            Write-Host "  FaceId: $($_.Face.FaceId), Confidence: $($_.Face.Confidence)"
        }
    } else {
        Write-Host "No match for $object"
    }
}
