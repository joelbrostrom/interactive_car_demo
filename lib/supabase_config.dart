import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// SUPABASE CONFIGURATION
// Change these values when forking for new demos
// ============================================

const supabaseUrl = 'https://nqxoxkcqexfvhkheugay.supabase.co';
const supabaseAnonKey = 'sb_publishable_ChHbkaN6Yk0NxSHgantOng_UeuTp1CR';

// Quick access to Supabase client
SupabaseClient get supabase => Supabase.instance.client;
