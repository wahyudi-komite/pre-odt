import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
import { APP_CONFIG } from "./config.js";

export const supabase = createClient(
    APP_CONFIG.supabaseUrl,
    APP_CONFIG.supabasePublishableKey,
    {
        realtime: {
            params: {
                eventsPerSecond: 10
            }
        }
    }
);
