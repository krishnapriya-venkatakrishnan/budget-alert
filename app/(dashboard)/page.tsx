export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">
          Your financial overview at a glance.
        </p>
      </div>
      <p className="text-muted-foreground text-sm">
        Charts and stats will appear here once transactions are uploaded.
      </p>
    </div>
  );
}
