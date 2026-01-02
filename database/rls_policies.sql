-- =====================================================
-- RLS POLICIES UNTUK SUPABASE STORAGE
-- File ini mengatur akses ke bucket:
-- - kos-images (gambar kos & kamar)
-- - bukti-pembayaran (bukti pembayaran)
-- Jalankan di Supabase SQL Editor dan sesuaikan dengan kebutuhan keamanan Anda.
-- =====================================================

-- =====================================================
-- RLS SUPABASE STORAGE - UNTUK APLIKASI TANPA SUPABASE AUTH
-- Bucket: kos-images
-- =====================================================

-- Bersihkan policy lama
DROP POLICY IF EXISTS "upload kos image" ON storage.objects;
DROP POLICY IF EXISTS "read kos image" ON storage.objects;
DROP POLICY IF EXISTS "update kos image" ON storage.objects;
DROP POLICY IF EXISTS "delete kos image" ON storage.objects;
DROP POLICY IF EXISTS "manage kos image" ON storage.objects;
DROP POLICY IF EXISTS "read bucket" ON storage.buckets;

-- 1. Izinkan semua user melihat bucket
CREATE POLICY "read bucket"
ON storage.buckets
FOR SELECT
USING (true);

-- 2. Public read gambar
CREATE POLICY "read kos image"
ON storage.objects
FOR SELECT
USING (bucket_id = 'kos-images');

-- 3. Izinkan upload (anon & authenticated)
CREATE POLICY "upload kos image"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'kos-images');

-- 4. Izinkan update
CREATE POLICY "update kos image"
ON storage.objects
FOR UPDATE
USING (bucket_id = 'kos-images')
WITH CHECK (bucket_id = 'kos-images');

-- 5. Izinkan delete
CREATE POLICY "delete kos image"
ON storage.objects
FOR DELETE
USING (bucket_id = 'kos-images');


-- =====================================================
-- RLS POLICIES untuk Bucket: bukti-pembayaran
-- =====================================================
-- NOTE: Karena menggunakan custom authentication,
-- kita buat policy PUBLIC untuk upload dan akses
-- =====================================================

-- HAPUS policy lama yang menggunakan authenticated role
DROP POLICY IF EXISTS "Authenticated users can upload payment proof" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view payment proofs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update payment proof" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete payment proof" ON storage.objects;

-- 1. Policy untuk INSERT (Upload bukti pembayaran) - PUBLIC
CREATE POLICY "Public can upload payment proof"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'bukti-pembayaran'
);

-- 2. Policy untuk SELECT (Melihat bukti pembayaran) - PUBLIC
CREATE POLICY "Public can view payment proofs"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'bukti-pembayaran'
);

-- 3. Policy untuk UPDATE (Update file) - PUBLIC
CREATE POLICY "Public can update payment proof"
ON storage.objects
FOR UPDATE
TO public
USING (
  bucket_id = 'bukti-pembayaran'
)
WITH CHECK (
  bucket_id = 'bukti-pembayaran'
);

-- 4. Policy untuk DELETE (Hapus file) - PUBLIC
CREATE POLICY "Public can delete payment proof"
ON storage.objects
FOR DELETE
TO public
USING (
  bucket_id = 'bukti-pembayaran'
);

-- =====================================================
-- VERIFIKASI: Cek policies yang sudah dibuat
-- =====================================================
-- SELECT 
--   schemaname,
--   tablename,
--   policyname,
--   permissive,
--   roles,
--   cmd,
--   qual,
--   with_check
-- FROM pg_policies
-- WHERE tablename = 'objects'
--   AND policyname LIKE '%payment%';

