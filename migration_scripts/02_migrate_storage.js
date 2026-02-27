const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// OLD PROJECT
const OLD_SUPABASE_URL = 'https://bgqcuykvsiejgqeiefpi.supabase.co';
const OLD_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJncWN1eWt2c2llamdxZWllZnBpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTc3MTU3NCwiZXhwIjoyMDgxMzQ3NTc0fQ.c0ygBcV3tXX0kjsUnPgTzaeiXqZILwdsnZJ8CoixS0k';

// NEW PROJECT
const NEW_SUPABASE_URL = 'http://supabasekong-ogw8kswcww8swko0c8gswsks.72.62.229.227.sslip.io';
const NEW_SERVICE_KEY = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoic2VydmljZV9yb2xlIn0.knWG9QJQ2i5g1xcc7wXVGHueMxvPwVfy3Nxb8RCQdmM';

const oldClient = createClient(OLD_SUPABASE_URL, OLD_SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
});

const newClient = createClient(NEW_SUPABASE_URL, NEW_SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
});

async function migrateStorage() {
  console.log('Starting Storage Migration...');

  // 1. List Buckets
  const { data: buckets, error: bucketsError } = await oldClient.storage.listBuckets();
  if (bucketsError) {
    console.error('Error listing buckets:', bucketsError);
    return;
  }

  console.log(`Found ${buckets.length} buckets.`);

  for (const bucket of buckets) {
    console.log(`Processing bucket: ${bucket.name} (public: ${bucket.public})`);

    // Create bucket in new project if not exists
    const { data: newBucket, error: createError } = await newClient.storage.createBucket(bucket.name, {
      public: bucket.public,
      fileSizeLimit: bucket.file_size_limit,
      allowedMimeTypes: bucket.allowed_mime_types
    });

    if (createError) {
      if (createError.message.includes('already exists')) {
        console.log(`Bucket ${bucket.name} already exists.`);
      } else {
        console.error(`Error creating bucket ${bucket.name}:`, createError);
        continue;
      }
    } else {
      console.log(`Bucket ${bucket.name} created.`);
    }

    // Migrate Files
    await migrateFiles(bucket.name);
  }

  console.log('Storage Migration Complete!');
}

async function migrateFiles(bucketName, path = '') {
  // List files in current path
  const { data: files, error: listError } = await oldClient.storage.from(bucketName).list(path, {
    limit: 100,
    offset: 0,
    sortBy: { column: 'name', order: 'asc' }
  });

  if (listError) {
    console.error(`Error listing files in ${bucketName}/${path}:`, listError);
    return;
  }

  for (const file of files) {
    const filePath = path ? `${path}/${file.name}` : file.name;

    if (file.id === null) {
      // It's a folder (Supabase returns folders with id null sometimes, or specific metadata)
      // Actually Supabase returns folders as separate entries.
      // We recurse.
      console.log(`Found folder: ${filePath}`);
      await migrateFiles(bucketName, filePath);
    } else {
      console.log(`Migrating file: ${filePath}`);

      // Download from old
      const { data: fileData, error: downloadError } = await oldClient.storage.from(bucketName).download(filePath);
      
      if (downloadError) {
        console.error(`Error downloading ${filePath}:`, downloadError);
        continue;
      }

      // Upload to new
      const { error: uploadError } = await newClient.storage.from(bucketName).upload(filePath, fileData, {
        contentType: file.metadata?.mimetype,
        upsert: true
      });

      if (uploadError) {
        console.error(`Error uploading ${filePath}:`, uploadError);
      } else {
        console.log(`Uploaded ${filePath}`);
      }
    }
  }
}

migrateStorage().catch(console.error);
