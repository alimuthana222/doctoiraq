export type SubscriptionTier = "free" | "pro" | "enterprise";

export type TenantClinic = {
  id: string;
  name: string;
  subdomain: string;
  subscriptionTier: SubscriptionTier;
  appointmentsToday: number;
  activeDoctors: number;
};

export type PlatformAlert = {
  id: string;
  type: "error" | "warning" | "info";
  message: string;
  source: string;
};
