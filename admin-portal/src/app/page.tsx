import { hasSupabaseEnv } from "@/lib/supabase";
import { platformAlerts, tenantClinics } from "@/lib/mock-data";

const tierLabel: Record<string, string> = {
  free: "Free",
  pro: "Pro",
  enterprise: "Enterprise",
};

export default function Home() {
  const activeTenants = tenantClinics.length;
  const totalAppointmentsToday = tenantClinics.reduce((acc, clinic) => acc + clinic.appointmentsToday, 0);
  const alertCount = platformAlerts.length;

  return (
    <main className="container">
      <section className="header">
        <h1>nabda Admin Portal</h1>
        <p>إدارة العيادات، مراقبة صحة المنصة، وتقديم دعم فني مركزي.</p>
        {!hasSupabaseEnv && (
          <p className="note" style={{ color: "#dff8f4" }}>
            العرض الحالي يعتمد بيانات تجريبية. أضف مفاتيح Supabase لقراءة البيانات الحقيقية.
          </p>
        )}
      </section>

      <section className="sections">
        <article className="card">
          <h2 className="title">العيادات النشطة</h2>
          <div className="kpi">{activeTenants}</div>
        </article>
        <article className="card">
          <h2 className="title">إجمالي مواعيد اليوم</h2>
          <div className="kpi">{totalAppointmentsToday}</div>
        </article>
        <article className="card">
          <h2 className="title">تنبيهات النظام</h2>
          <div className="kpi">{alertCount}</div>
        </article>
      </section>

      <section className="tableWrap">
        <h2 className="title">إدارة العيادات (Tenants)</h2>
        <table className="table">
          <thead>
            <tr>
              <th>اسم العيادة</th>
              <th>النطاق الفرعي</th>
              <th>الباقة</th>
              <th>مواعيد اليوم</th>
              <th>أطباء نشطون</th>
            </tr>
          </thead>
          <tbody>
            {tenantClinics.map((clinic) => (
              <tr key={clinic.id}>
                <td>{clinic.name}</td>
                <td>{clinic.subdomain}.nabda.app</td>
                <td>{tierLabel[clinic.subscriptionTier]}</td>
                <td>{clinic.appointmentsToday}</td>
                <td>{clinic.activeDoctors}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="tableWrap">
        <h2 className="title">مراقبة عامة للنظام</h2>
        <table className="table">
          <thead>
            <tr>
              <th>المصدر</th>
              <th>التنبيه</th>
              <th>الحالة</th>
            </tr>
          </thead>
          <tbody>
            {platformAlerts.map((alert) => {
              const className =
                alert.type === "error"
                  ? "badge badgeDanger"
                  : alert.type === "warning"
                    ? "badge badgeWarn"
                    : "badge badgeOk";

              return (
                <tr key={alert.id}>
                  <td>{alert.source}</td>
                  <td>{alert.message}</td>
                  <td>
                    <span className={className}>
                      {alert.type === "error" ? "Error" : alert.type === "warning" ? "Warning" : "Info"}
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </section>
    </main>
  );
}
