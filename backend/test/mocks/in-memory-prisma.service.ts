import * as crypto from 'crypto';

export class InMemoryPrismaService {
  public patients = new Map<string, any>();
  public medications = new Map<string, any>();
  public intakeLogs = new Map<string, any>();
  public auditLogs = new Map<string, any>();

  public patient = {
    upsert: async ({ where, update, create }: any) => {
      let existing = null;
      if (where.rutBlindIndex) {
        existing = Array.from(this.patients.values()).find(
          (p) => p.rutBlindIndex === where.rutBlindIndex,
        );
      } else if (where.id) {
        existing = this.patients.get(where.id);
      }

      if (existing) {
        const updated = { ...existing, ...update, updatedAt: new Date() };
        this.patients.set(existing.id, updated);
        return updated;
      }

      const id = create.id || crypto.randomUUID();
      const record = { ...create, id, createdAt: new Date(), updatedAt: new Date() };
      this.patients.set(id, record);
      return record;
    },

    findUnique: async ({ where, include }: any) => {
      let found = null;
      if (where.id) {
        found = this.patients.get(where.id);
      } else if (where.rutBlindIndex) {
        found = Array.from(this.patients.values()).find(
          (p) => p.rutBlindIndex === where.rutBlindIndex,
        );
      }

      if (!found) return null;
      const res = { ...found };
      if (include?.medications) {
        res.medications = Array.from(this.medications.values()).filter(
          (m) => m.patientId === found.id && (include.medications.where?.isActive !== undefined ? m.isActive === include.medications.where.isActive : true),
        );
      }
      return res;
    },

    create: async ({ data }: any) => {
      const id = data.id || crypto.randomUUID();
      const record = { ...data, id, createdAt: new Date(), updatedAt: new Date() };
      this.patients.set(id, record);
      return record;
    },

    update: async ({ where, data }: any) => {
      const existing = this.patients.get(where.id);
      if (!existing) throw new Error(`Patient ${where.id} not found`);
      const updated = { ...existing, ...data, updatedAt: new Date() };
      this.patients.set(where.id, updated);
      return updated;
    },
  };

  public medication = {
    upsert: async ({ where, update, create }: any) => {
      let existing = this.medications.get(where.id);
      if (existing) {
        const updated = { ...existing, ...update };
        this.medications.set(where.id, updated);
        return updated;
      }
      const id = create.id || where.id || crypto.randomUUID();
      const record = { ...create, id, isActive: create.isActive !== undefined ? create.isActive : true };
      this.medications.set(id, record);
      return record;
    },

    findFirst: async ({ where }: any) => {
      return Array.from(this.medications.values()).find((m) => {
        let match = true;
        if (where.patientId && m.patientId !== where.patientId) match = false;
        if (where.commercialName?.contains) {
          const needle = where.commercialName.contains.toLowerCase();
          if (!m.commercialName.toLowerCase().includes(needle)) match = false;
        }
        return match;
      }) || null;
    },

    findMany: async ({ where }: any) => {
      return Array.from(this.medications.values()).filter((m) => {
        if (where?.patientId && m.patientId !== where.patientId) return false;
        return true;
      });
    },

    create: async ({ data }: any) => {
      const id = data.id || crypto.randomUUID();
      const record = { ...data, id, isActive: data.isActive !== undefined ? data.isActive : true };
      this.medications.set(id, record);
      return record;
    },

    update: async ({ where, data }: any) => {
      const existing = this.medications.get(where.id);
      if (!existing) throw new Error(`Medication ${where.id} not found`);
      const updated = { ...existing, ...data };
      this.medications.set(where.id, updated);
      return updated;
    },
  };

  public intakeLog = {
    upsert: async ({ where, update, create }: any) => {
      let existing = this.intakeLogs.get(where.id);
      if (existing) {
        const updated = { ...existing, ...update };
        this.intakeLogs.set(where.id, updated);
        return updated;
      }
      const id = create.id || where.id || crypto.randomUUID();
      const record = { ...create, id };
      this.intakeLogs.set(id, record);
      return record;
    },

    findFirst: async ({ where, include }: any) => {
      const found = Array.from(this.intakeLogs.values()).find((i) => {
        if (where.id && i.id !== where.id) return false;
        if (where.patientId && i.patientId !== where.patientId) return false;
        return true;
      });
      if (!found) return null;
      const res = { ...found };
      if (include?.medication) {
        res.medication = this.medications.get(found.medicationId);
      }
      return res;
    },

    findMany: async ({ where, include, orderBy }: any) => {
      let list = Array.from(this.intakeLogs.values()).filter((i) => {
        if (where?.patientId && i.patientId !== where.patientId) return false;
        if (where?.scheduledTime?.gte && new Date(i.scheduledTime) < new Date(where.scheduledTime.gte)) return false;
        if (where?.scheduledTime?.lte && new Date(i.scheduledTime) > new Date(where.scheduledTime.lte)) return false;
        return true;
      });

      if (include?.medication) {
        list = list.map((i) => ({
          ...i,
          medication: this.medications.get(i.medicationId),
        }));
      }

      if (orderBy?.scheduledTime === 'asc') {
        list.sort((a, b) => new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime());
      } else if (orderBy?.scheduledTime === 'desc') {
        list.sort((a, b) => new Date(b.scheduledTime).getTime() - new Date(a.scheduledTime).getTime());
      }

      return list;
    },

    create: async ({ data, include }: any) => {
      const id = data.id || crypto.randomUUID();
      const record = { ...data, id };
      this.intakeLogs.set(id, record);
      if (include?.medication) {
        return { ...record, medication: this.medications.get(record.medicationId) };
      }
      return record;
    },

    update: async ({ where, data, include }: any) => {
      const existing = this.intakeLogs.get(where.id);
      if (!existing) throw new Error(`IntakeLog ${where.id} not found`);
      const updated = { ...existing, ...data };
      this.intakeLogs.set(where.id, updated);
      if (include?.medication) {
        return { ...updated, medication: this.medications.get(updated.medicationId) };
      }
      return updated;
    },
  };

  public auditLog = {
    create: async ({ data }: any) => {
      const id = data.id || crypto.randomUUID();
      const record = { ...data, id };
      this.auditLogs.set(id, record);
      return record;
    },

    findFirst: async ({ where, orderBy }: any) => {
      let list = Array.from(this.auditLogs.values()).filter((a) => {
        if (where?.patientId && a.patientId !== where.patientId) return false;
        return true;
      });
      if (orderBy?.timestamp === 'desc') {
        list.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
      }
      return list[0] || null;
    },
  };

  public reset() {
    this.patients.clear();
    this.medications.clear();
    this.intakeLogs.clear();
    this.auditLogs.clear();
  }
}
