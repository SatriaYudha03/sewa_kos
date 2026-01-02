-- =====================================================
-- Skema database utama untuk aplikasi Sewa Kos
-- File ini berisi definisi tabel utama yang digunakan aplikasi.
-- Jika menjalankan di Supabase, gunakan SQL Editor dan sesuaikan bila perlu.
-- WARNING: This schema is for context only and may need adjustment
-- depending on your existing database (sequences, enums, etc.).
-- =====================================================

-- ENUM TYPES (sesuaikan dengan kebutuhan jika sudah ada di DB)
-- Jika tipe ini sudah ada di database Anda, bagian ini bisa di-skip atau dihapus.
-- Supabase baru biasanya belum memiliki tipe custom ini.

-- Status kamar: 'tersedia', 'terisi', 'perbaikan'
CREATE TYPE public.status_kamar_enum AS ENUM (
  'tersedia',
  'terisi',
  'perbaikan'
);

-- Status pemesanan: 'menunggu_pembayaran', 'terkonfirmasi', 'dibatalkan', 'selesai'
CREATE TYPE public.status_pemesanan_enum AS ENUM (
  'menunggu_pembayaran',
  'terkonfirmasi',
  'dibatalkan',
  'selesai'
);

-- Status pembayaran: 'menunggu_verifikasi', 'terverifikasi', 'gagal'
CREATE TYPE public.status_pembayaran_enum AS ENUM (
  'menunggu_verifikasi',
  'terverifikasi',
  'gagal'
);

-- =====================================================
-- TABEL-TABEL UTAMA
-- =====================================================

CREATE TABLE public.roles (
  id bigint NOT NULL DEFAULT nextval('roles_id_seq'::regclass),
  role_name character varying NOT NULL UNIQUE,
  CONSTRAINT roles_pkey PRIMARY KEY (id)
);

CREATE TABLE public.users (
  id bigint NOT NULL DEFAULT nextval('users_id_seq'::regclass),
  username character varying NOT NULL UNIQUE,
  password character varying NOT NULL,
  email character varying UNIQUE,
  role_id bigint NOT NULL,
  nama_lengkap character varying,
  no_telepon character varying,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  auth_uid uuid UNIQUE,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id)
);

CREATE TABLE public.kos (
  id bigint NOT NULL DEFAULT nextval('kos_id_seq'::regclass),
  user_id bigint NOT NULL,
  nama_kos character varying NOT NULL,
  alamat text,
  deskripsi text,
  foto_utama_url text,
  fasilitas_umum text,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT kos_pkey PRIMARY KEY (id),
  CONSTRAINT kos_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

CREATE TABLE public.kamar_kos (
  id bigint NOT NULL DEFAULT nextval('kamar_kos_id_seq'::regclass),
  kos_id bigint NOT NULL,
  nama_kamar character varying NOT NULL,
  harga_sewa numeric NOT NULL,
  luas_kamar character varying,
  fasilitas text,
  status USER-DEFINED DEFAULT 'tersedia'::status_kamar_enum,
  foto_kamar_url text,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT kamar_kos_pkey PRIMARY KEY (id),
  CONSTRAINT kamar_kos_kos_id_fkey FOREIGN KEY (kos_id) REFERENCES public.kos(id)
);

CREATE TABLE public.pemesanan (
  id bigint NOT NULL DEFAULT nextval('pemesanan_id_seq'::regclass),
  user_id bigint NOT NULL,
  kamar_id bigint NOT NULL,
  tanggal_mulai date NOT NULL,
  durasi_sewa integer NOT NULL,
  tanggal_selesai date NOT NULL,
  total_harga numeric NOT NULL,
  status_pemesanan USER-DEFINED DEFAULT 'menunggu_pembayaran'::status_pemesanan_enum,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT pemesanan_pkey PRIMARY KEY (id),
  CONSTRAINT pemesanan_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT pemesanan_kamar_id_fkey FOREIGN KEY (kamar_id) REFERENCES public.kamar_kos(id)
);

CREATE TABLE public.detail_pembayaran (
  id bigint NOT NULL DEFAULT nextval('detail_pembayaran_id_seq'::regclass),
  pemesanan_id bigint NOT NULL,
  jumlah_bayar numeric NOT NULL,
  jenis_pembayaran character varying,
  tanggal_pembayaran timestamp without time zone DEFAULT now(),
  metode_pembayaran character varying,
  status_pembayaran USER-DEFINED DEFAULT 'menunggu_verifikasi'::status_pembayaran_enum,
  bukti_transfer_url text,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT detail_pembayaran_pkey PRIMARY KEY (id),
  CONSTRAINT detail_pembayaran_pemesanan_id_fkey FOREIGN KEY (pemesanan_id) REFERENCES public.pemesanan(id)
);
