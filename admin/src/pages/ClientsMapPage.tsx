import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";
import "leaflet/dist/leaflet.css";
import { api } from "../lib/api";
import type { ClientMapPoint } from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";

// Vite bundles the default Leaflet marker images under hashed URLs, so the
// package's built-in relative paths never resolve — point the default icon
// at the bundled assets explicitly.
const markerIconInstance = L.icon({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

export function ClientsMapPage() {
  const { t } = useLang();
  const navigate = useNavigate();

  const { data, isLoading } = useQuery({
    queryKey: ["clients-map"],
    queryFn: async () =>
      (await api.get<ClientMapPoint[]>("/admin/clients/map")).data,
  });

  const center: [number, number] =
    data && data.length > 0 ? [data[0].latitude, data[0].longitude] : [41.3111, 69.2797]; // Tashkent

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <PageHeader
        title={t.clients.mapTitle}
        subtitle={
          isLoading
            ? t.common.loading
            : t.clients.mapSubtitle(data?.length ?? 0)
        }
      />

      <div className="mt-4 overflow-hidden rounded-2xl border border-line" style={{ height: "70vh" }}>
        {!isLoading && (
          <MapContainer center={center} zoom={data && data.length > 0 ? 6 : 5} style={{ height: "100%", width: "100%" }}>
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            {data?.map((c) => (
              <Marker
                key={c.id}
                position={[c.latitude, c.longitude]}
                icon={markerIconInstance}
                eventHandlers={{ click: () => navigate(`/clients/${c.id}`) }}
              >
                <Popup>
                  <div className="text-sm">
                    <div className="font-bold">{c.full_name ?? t.clients.unnamed}</div>
                    {c.phone && <div>📞 {c.phone}</div>}
                    <div className="text-muted">
                      {[c.city, c.region, c.country].filter(Boolean).join(", ") || "—"}
                    </div>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        )}
      </div>
    </div>
  );
}
