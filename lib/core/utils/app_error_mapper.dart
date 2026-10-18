import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorMapper {
  AppErrorMapper._();

  static String toUserMessage(Object error) {
    if (error is PostgrestException) {
      return _mapPostgrestException(error);
    }

    if (error is AuthException) {
      return _mapAuthException(error);
    }

    if (error is SocketException ||
        error is TimeoutException ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('ClientException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Network is unreachable')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda dan coba lagi.';
    }

    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return 'Terjadi kendala pada sistem. Silakan coba beberapa saat lagi.';
  }

  static String _mapPostgrestException(PostgrestException e) {
    final code = e.code;
    final rawMessage = e.message;

    switch (code) {
      case '42501':
        return 'Akses ditolak. Silakan masuk terlebih dahulu atau periksa izin akun Anda.';

      case 'P0001':
        if (rawMessage.contains('Alur belajar bertahap') ||
            rawMessage.contains('modul sebelumnya')) {
          return rawMessage.isNotEmpty
              ? rawMessage
              : 'Alur belajar bertahap: Anda harus menyelesaikan modul sebelumnya terlebih dahulu.';
        }
        if (rawMessage.contains('Asesmen Akhir') ||
            rawMessage.contains('modul pembelajaran wajib')) {
          return rawMessage.isNotEmpty
              ? rawMessage
              : 'Syarat belum terpenuhi: Selesaikan seluruh 5 modul terlebih dahulu.';
        }
        if (rawMessage.contains('80%')) {
          return 'Syarat belum terpenuhi: Nilai asesmen akhir minimal 80% untuk menerbitkan sertifikat.';
        }
        return rawMessage.isNotEmpty
            ? rawMessage
            : 'Persyaratan belajar belum terpenuhi.';

      case 'P0002':
        return 'Materi atau kuis yang dicari tidak ditemukan atau belum dipublikasikan.';

      case 'P0003':
        return 'Batas percobaan tercapai. Anda hanya dapat mengikuti Asesmen Akhir maksimal 3 kali dalam 24 jam. Silakan coba lagi besok.';

      case '22023':
        return 'Data jawaban atau parameter yang dikirim tidak valid. Silakan muat ulang halaman.';

      default:
        if (rawMessage.isNotEmpty && !rawMessage.contains('syntax error')) {
          return rawMessage;
        }
        return 'Terjadi kesalahan pada server (Kode: ${code ?? "UNKNOWN"}). Silakan coba lagi.';
    }
  }

  static String _mapAuthException(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('email not confirmed')) {
      return 'Email atau kata sandi tidak cocok. Silakan periksa kembali.';
    }

    if (message.contains('user already registered') ||
        message.contains('email already in use') ||
        message.contains('already registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk dengan akun Anda.';
    }

    if (message.contains('password should be at least') ||
        message.contains('password is too short')) {
      return 'Kata sandi minimal terdiri dari 6 karakter.';
    }

    if (message.contains('valid email')) {
      return 'Format alamat email tidak valid.';
    }

    return e.message.isNotEmpty
        ? e.message
        : 'Gagal melakukan proses autentikasi. Silakan coba lagi.';
  }
}

