package com.valinor.heroclix_simulator_trainer

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var pendingCode = 0
    private val openCode = 4401
    private val saveCode = 4402

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.valinor.heroclixtrainer/files")
            .setMethodCallHandler { call, result ->
                if (call.method == "directory") {
                    result.success(File(filesDir, "scenarios_v1").absolutePath)
                    return@setMethodCallHandler
                }
                if (pending != null) {
                    result.error("busy", "Ya hay una operación de archivo en curso.", null)
                    return@setMethodCallHandler
                }
                try {
                    when (call.method) {
                        "pickJson" -> {
                            pending = result; pendingCode = openCode
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "*/*"
                                putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "application/octet-stream"))
                            }
                            startActivityForResult(intent, openCode)
                        }
                        "saveFile", "shareFile" -> {
                            val bytes = call.argument<ByteArray>("bytes") ?: error("Faltan datos.")
                            val name = call.argument<String>("name") ?: error("Falta nombre.")
                            val mime = call.argument<String>("mime") ?: error("Falta tipo.")
                            val extension = mapOf("application/json" to "json", "image/png" to "png", "text/plain" to "txt")[mime]
                                ?: error("Tipo de archivo inválido.")
                            require(name.matches(Regex("[A-Za-z0-9_-]{1,100}\\.$extension"))) { "Nombre de archivo inválido para este tipo." }
                            val max = if (mime == "image/png") 16 * 1024 * 1024 else 2 * 1024 * 1024
                            require(bytes.isNotEmpty() && bytes.size <= max) { "El archivo supera el límite permitido." }
                            if (call.method == "saveFile") {
                                pending = result; pendingBytes = bytes; pendingCode = saveCode
                                startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    type = mime
                                    putExtra(Intent.EXTRA_TITLE, name)
                                }, saveCode)
                            } else {
                                pending = result
                                executor.execute {
                                    try {
                                        val directory = File(cacheDir, "exports").apply { mkdirs() }
                                        directory.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 86400000L }?.forEach { it.delete() }
                                        val file = File(directory, "${System.nanoTime()}_$name")
                                        file.outputStream().use { it.write(bytes) }
                                        val uri = FileProvider.getUriForFile(this, "$packageName.exports", file)
                                        runOnUiThread {
                                            try {
                                                val send = Intent(Intent.ACTION_SEND).apply {
                                                    type = mime
                                                    putExtra(Intent.EXTRA_STREAM, uri)
                                                    clipData = ClipData.newRawUri(name, uri)
                                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                                }
                                                startActivity(Intent.createChooser(send, "Compartir escenario"))
                                                finishPending(null)
                                            } catch (exception: Exception) { failPending(exception) }
                                        }
                                    } catch (exception: Exception) { runOnUiThread { failPending(exception) } }
                                }
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (exception: Exception) {
                    if (pending != null) failPending(exception) else result.error("file_error", exception.message, null)
                }
            }
    }

    @Deprecated("Uses the system document picker with FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pendingCode || pending == null) return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            finishPending(if (requestCode == saveCode) false else null)
            return
        }
        val uri: Uri = data.data!!
        if (uri.scheme != "content") { failPending(IllegalArgumentException("El proveedor no devolvió un documento válido.")); return }
        val bytes = pendingBytes
        executor.execute {
            try {
                if (requestCode == saveCode) {
                    contentResolver.openOutputStream(uri, "wt")?.use { stream ->
                        stream.write(bytes ?: error("No hay datos para exportar.")); stream.flush()
                    } ?: error("No se pudo abrir el destino.")
                    runOnUiThread { finishPending(true) }
                } else {
                    var name = "escenario.json"
                    contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            val sizeColumn = cursor.getColumnIndex(OpenableColumns.SIZE)
                            if (sizeColumn >= 0 && !cursor.isNull(sizeColumn)) require(cursor.getLong(sizeColumn) <= 2 * 1024 * 1024) { "El JSON supera 2 MiB." }
                            val nameColumn = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                            if (nameColumn >= 0) name = (cursor.getString(nameColumn) ?: name).take(128)
                        }
                    }
                    val output = ByteArrayOutputStream()
                    contentResolver.openInputStream(uri)?.use { stream ->
                        val buffer = ByteArray(8192)
                        while (true) {
                            val count = stream.read(buffer)
                            if (count < 0) break
                            require(output.size() + count <= 2 * 1024 * 1024) { "El JSON supera 2 MiB." }
                            output.write(buffer, 0, count)
                        }
                    } ?: error("No se pudo leer el archivo.")
                    val payload = mapOf("bytes" to output.toByteArray(), "name" to name)
                    runOnUiThread { finishPending(payload) }
                }
            } catch (exception: Exception) { runOnUiThread { failPending(exception) } }
        }
    }
    private fun finishPending(value: Any?) {
        val result = pending
        pending = null; pendingBytes = null; pendingCode = 0
        result?.success(value)
    }
    private fun failPending(exception: Exception) {
        val result = pending
        pending = null; pendingBytes = null; pendingCode = 0
        result?.error("file_error", exception.message ?: "No se pudo completar la operación de archivo.", null)
    }
    override fun onDestroy() {
        if (pending != null) failPending(IllegalStateException("La operación de archivo se canceló al cerrar la actividad."))
        executor.shutdown()
        super.onDestroy()
    }
}

class ExportFileProvider : FileProvider()
