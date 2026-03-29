import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    return NextResponse.json(
      { data: null, error: { message: "unauthorized" } },
      { status: 401 },
    );
  }

  const { error } = await supabase.auth.signOut();

  if (error) {
    return NextResponse.json(
      { data: null, error: { message: error.message } },
      { status: 500 },
    );
  }

  return NextResponse.json({ data: { signedOut: true }, error: null });
}
