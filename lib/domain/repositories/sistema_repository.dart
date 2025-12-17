import '../entities/envio.dart';
import '../entities/reporte.dart';
import '../entities/empleado.dart';
import '../entities/rol.dart';

abstract class EnvioRepository {
  Future<List<Envio>> getAllEnvios();
  Future<Envio?> getEnvioById(int id);
  Future<Envio?> getEnvioByNumeroRastreo(String numeroRastreo);
  Future<Envio> createEnvio(Envio envio);
  Future<Envio> updateEnvio(Envio envio);
  Future<void> deleteEnvio(int id);
  Future<List<Envio>> getEnviosByEstatus(EnvioEstatus estatus);
  Future<List<Envio>> getEnviosByUbicacionOrigen(int idUbicacion);
  Future<List<Envio>> getEnviosByUbicacionDestino(int idUbicacion);
}

abstract class ReporteRepository {
  Future<List<Reporte>> getAllReportes();
  Future<Reporte?> getReporteById(int id);
  Future<List<Reporte>> getReportesByEmpleado(String idEmpleado);
  Future<List<Reporte>> getReportesByTipo(ReporteTipo tipo);
  Future<Reporte> createReporte(Reporte reporte);
  Future<void> deleteReporte(int id);
}

abstract class EmpleadoRepository {
  Future<List<Empleado>> getAllEmpleados();
  Future<Empleado?> getEmpleadoById(String id);
  Future<Empleado?> getEmpleadoByNombreUsuario(String nombreUsuario);
  Future<Empleado> createEmpleado(Empleado empleado);
  Future<Empleado> updateEmpleado(Empleado empleado);
  Future<void> deleteEmpleado(String id);
  Future<List<Rol>> getRolesByEmpleado(String idEmpleado);
  Future<void> asignarRol(String idEmpleado, int idRol);
  Future<void> removerRol(String idEmpleado, int idRol);
}

abstract class RolRepository {
  Future<List<Rol>> getAllRoles();
  Future<Rol?> getRolById(int id);
  Future<Rol?> getRolByNombre(String nombre);
  Future<Rol> createRol(Rol rol);
  Future<Rol> updateRol(Rol rol);
  Future<void> deleteRol(int id);
}

