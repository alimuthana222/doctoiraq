import { availabilityRules, staffMembers, todayAppointments } from "@/lib/mock-data";
import { hasSupabaseEnv } from "@/lib/supabase";

const statusLabel: Record<string, string> = {
  pending: "قيد الانتظار",
  confirmed: "مؤكد",
  completed: "مكتمل",
  cancelled: "ملغي",
  no_show: "لم يحضر",
};

export default function Home() {
  const totalAppointments = todayAppointments.length;
  const confirmed = todayAppointments.filter((a) => a.status === "confirmed").length;
  const pending = todayAppointments.filter((a) => a.status === "pending").length;

  return (
    <main className="wrapper">
      <aside className="sidebar">
        <div className="brand">nabda</div>
        <div className="tagline">Healthcare begins here</div>
        <nav className="nav">
          <div className="navItem active">تقويم المواعيد</div>
          <div className="navItem">أوقات العمل والإجازات</div>
          <div className="navItem">المرضى والسجلات</div>
          <div className="navItem">التقارير</div>
          <div className="navItem">إدارة الموظفين</div>
        </nav>
      </aside>

      <section className="content">
        <div className="hero">
          <h1>لوحة تحكم العيادة</h1>
          <p>متابعة المواعيد، إدارة الأطباء، وتحديث جدول العيادة من مكان واحد.</p>
          {!hasSupabaseEnv && (
            <p className="note" style={{ color: "#dff8f4" }}>
              حالياً يتم العرض ببيانات تجريبية. أضف متغيرات Supabase لتفعيل البيانات الحقيقية.
            </p>
          )}
        </div>

        <div className="cards">
          <article className="card">
            <p>مواعيد اليوم</p>
            <div className="value">{totalAppointments}</div>
          </article>
          <article className="card">
            <p>مواعيد مؤكدة</p>
            <div className="value">{confirmed}</div>
          </article>
          <article className="card">
            <p>قيد الانتظار</p>
            <div className="value">{pending}</div>
          </article>
          <article className="card">
            <p>أعضاء الفريق</p>
            <div className="value">{staffMembers.length}</div>
          </article>
        </div>

        <div className="tableWrap">
          <h2 className="sectionTitle">تقويم اليوم</h2>
          <table className="table">
            <thead>
              <tr>
                <th>الوقت</th>
                <th>المريض</th>
                <th>الطبيب</th>
                <th>التخصص</th>
                <th>الحالة</th>
              </tr>
            </thead>
            <tbody>
              {todayAppointments.map((appointment) => {
                const isPending = appointment.status === "pending";
                return (
                  <tr key={appointment.id}>
                    <td>{new Date(appointment.scheduledAt).toLocaleTimeString("ar-IQ", { hour: "2-digit", minute: "2-digit" })}</td>
                    <td>{appointment.patientName}</td>
                    <td>{appointment.doctorName}</td>
                    <td>{appointment.specialty}</td>
                    <td>
                      <span className={`badge ${isPending ? "badgePending" : "badgeSuccess"}`}>
                        {statusLabel[appointment.status]}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <div className="gridTwo">
          <div className="tableWrap">
            <h2 className="sectionTitle">إدارة أوقات العمل</h2>
            <table className="table">
              <thead>
                <tr>
                  <th>الطبيب</th>
                  <th>اليوم</th>
                  <th>من</th>
                  <th>إلى</th>
                  <th>مدة الموعد</th>
                </tr>
              </thead>
              <tbody>
                {availabilityRules.map((rule, index) => (
                  <tr key={`${rule.doctorName}-${rule.day}-${index}`}>
                    <td>{rule.doctorName}</td>
                    <td>{rule.day}</td>
                    <td>{rule.start}</td>
                    <td>{rule.end}</td>
                    <td>{rule.slotDurationMinutes} دقيقة</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="tableWrap">
            <h2 className="sectionTitle">إدارة الموظفين</h2>
            <table className="table">
              <thead>
                <tr>
                  <th>الاسم</th>
                  <th>الدور</th>
                  <th>التخصص</th>
                </tr>
              </thead>
              <tbody>
                {staffMembers.map((member) => (
                  <tr key={member.id}>
                    <td>{member.name}</td>
                    <td>{member.role}</td>
                    <td>{member.specialty ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </main>
  );
}
