--
-- PostgreSQL database dump
--

\restrict chZxoPqVgz6Q2WApY0b4tlWgClVhL9PQP8WLeVHk9NSdI5jFuzB68G5HsejaJdb

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: driver_earnings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.driver_earnings (
    id bigint NOT NULL,
    app_fee numeric(38,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    gross_amount numeric(38,2) NOT NULL,
    net_amount numeric(38,2) NOT NULL,
    status character varying(255) NOT NULL,
    driver_id bigint NOT NULL,
    ride_id bigint NOT NULL
);


ALTER TABLE public.driver_earnings OWNER TO postgres;

--
-- Name: driver_earnings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.driver_earnings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.driver_earnings_id_seq OWNER TO postgres;

--
-- Name: driver_earnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.driver_earnings_id_seq OWNED BY public.driver_earnings.id;


--
-- Name: driver_notification_queue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.driver_notification_queue (
    id bigint NOT NULL,
    driver_id bigint NOT NULL,
    driver_name character varying(255),
    notified_at timestamp(6) without time zone,
    queue_order integer NOT NULL,
    responded_at timestamp(6) without time zone,
    ride_id bigint NOT NULL,
    status character varying(255) NOT NULL,
    CONSTRAINT driver_notification_queue_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'NOTIFIED'::character varying, 'TIMEOUT'::character varying, 'SKIPPED'::character varying, 'ACCEPTED'::character varying])::text[])))
);


ALTER TABLE public.driver_notification_queue OWNER TO postgres;

--
-- Name: driver_notification_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.driver_notification_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.driver_notification_queue_id_seq OWNER TO postgres;

--
-- Name: driver_notification_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.driver_notification_queue_id_seq OWNED BY public.driver_notification_queue.id;


--
-- Name: driver_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.driver_profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    license_number character varying(100) NOT NULL,
    vehicle_number character varying(100) NOT NULL,
    vehicle_type character varying(50) NOT NULL,
    vehicle_model character varying(100),
    vehicle_color character varying(50),
    is_verified boolean DEFAULT false,
    is_active boolean DEFAULT false,
    average_rating double precision DEFAULT 5.0,
    total_rides bigint DEFAULT 0,
    current_latitude double precision,
    current_longitude double precision,
    is_online boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    verified_at timestamp without time zone,
    last_seen_at timestamp(6) without time zone
);


ALTER TABLE public.driver_profiles OWNER TO postgres;

--
-- Name: driver_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.driver_profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.driver_profiles_id_seq OWNER TO postgres;

--
-- Name: driver_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.driver_profiles_id_seq OWNED BY public.driver_profiles.id;


--
-- Name: game_rooms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_rooms (
    id bigint NOT NULL,
    board_state text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    current_turn character varying(255),
    finished_at timestamp(6) without time zone,
    game_status character varying(255),
    player1id bigint NOT NULL,
    player1symbol character varying(255) NOT NULL,
    player2id bigint,
    player2symbol character varying(255),
    winner character varying(255)
);


ALTER TABLE public.game_rooms OWNER TO postgres;

--
-- Name: game_rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.game_rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.game_rooms_id_seq OWNER TO postgres;

--
-- Name: game_rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.game_rooms_id_seq OWNED BY public.game_rooms.id;


--
-- Name: location_updates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location_updates (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    ride_id bigint,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.location_updates OWNER TO postgres;

--
-- Name: location_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.location_updates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.location_updates_id_seq OWNER TO postgres;

--
-- Name: location_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.location_updates_id_seq OWNED BY public.location_updates.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    sent_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20),
    receiver_id bigint NOT NULL,
    sender_id bigint NOT NULL,
    ride_id bigint
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO postgres;

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_read boolean DEFAULT false,
    related_user_id character varying(255),
    title character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    user_id bigint NOT NULL
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: otp_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.otp_codes (
    id bigint NOT NULL,
    code character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    email character varying(255) NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    used boolean NOT NULL
);


ALTER TABLE public.otp_codes OWNER TO postgres;

--
-- Name: otp_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.otp_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.otp_codes_id_seq OWNER TO postgres;

--
-- Name: otp_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.otp_codes_id_seq OWNED BY public.otp_codes.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id bigint NOT NULL,
    ride_id bigint NOT NULL,
    amount numeric(38,2) NOT NULL,
    payment_method character varying(50) NOT NULL,
    status character varying(50) NOT NULL,
    transaction_id character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    completed_at timestamp without time zone
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_id_seq OWNER TO postgres;

--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: profile_photos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile_photos (
    id bigint NOT NULL,
    photo_url character varying(255) NOT NULL,
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    user_id bigint NOT NULL
);


ALTER TABLE public.profile_photos OWNER TO postgres;

--
-- Name: profile_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profile_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profile_photos_id_seq OWNER TO postgres;

--
-- Name: profile_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profile_photos_id_seq OWNED BY public.profile_photos.id;


--
-- Name: ratings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ratings (
    id bigint NOT NULL,
    ride_id bigint NOT NULL,
    rater_id bigint NOT NULL,
    ratee_id bigint NOT NULL,
    rating integer NOT NULL,
    feedback text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ratings OWNER TO postgres;

--
-- Name: ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ratings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ratings_id_seq OWNER TO postgres;

--
-- Name: ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ratings_id_seq OWNED BY public.ratings.id;


--
-- Name: ride_audit_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ride_audit_events (
    id bigint NOT NULL,
    actor character varying(20),
    actor_id bigint,
    actor_name character varying(100),
    city character varying(100),
    correlation_id character varying(64),
    country character varying(100),
    created_at timestamp(6) without time zone NOT NULL,
    details jsonb,
    event_type character varying(50) NOT NULL,
    keep_forever boolean NOT NULL,
    latitude double precision,
    longitude double precision,
    ride_id bigint,
    "timestamp" timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.ride_audit_events OWNER TO postgres;

--
-- Name: ride_audit_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ride_audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ride_audit_events_id_seq OWNER TO postgres;

--
-- Name: ride_audit_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ride_audit_events_id_seq OWNED BY public.ride_audit_events.id;


--
-- Name: ride_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ride_events (
    id bigint NOT NULL,
    details character varying(255),
    event_type character varying(255) NOT NULL,
    ride_id bigint NOT NULL,
    "timestamp" timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL,
    CONSTRAINT ride_events_event_type_check CHECK (((event_type)::text = ANY ((ARRAY['REQUESTED'::character varying, 'ACCEPTED'::character varying, 'DRIVER_ARRIVED'::character varying, 'STARTED'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying])::text[])))
);


ALTER TABLE public.ride_events OWNER TO postgres;

--
-- Name: ride_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ride_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ride_events_id_seq OWNER TO postgres;

--
-- Name: ride_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ride_events_id_seq OWNED BY public.ride_events.id;


--
-- Name: rides; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rides (
    id bigint NOT NULL,
    rider_id bigint NOT NULL,
    driver_id bigint,
    pickup_latitude double precision NOT NULL,
    pickup_longitude double precision NOT NULL,
    pickup_address character varying(255) NOT NULL,
    dropoff_latitude double precision NOT NULL,
    dropoff_longitude double precision NOT NULL,
    dropoff_address character varying(255) NOT NULL,
    status character varying(50) NOT NULL,
    ride_type character varying(50) NOT NULL,
    estimated_fare numeric(38,2),
    final_fare numeric(38,2),
    estimated_distance double precision,
    estimated_duration bigint,
    requested_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    accepted_at timestamp without time zone,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    cancelled_at timestamp without time zone,
    cancellation_reason text,
    arrived_at_pickup_at timestamp(6) without time zone,
    driver_current_latitude double precision,
    driver_current_longitude double precision,
    driver_location_updated_at timestamp(6) without time zone,
    driver_arrived_at timestamp(6) without time zone,
    last_timeout_notification timestamp(6) without time zone,
    search_radius_km double precision,
    selected_ride_type character varying(255),
    version bigint,
    cancelled_by character varying(255),
    payment_method character varying(255),
    scheduled_ride_id bigint,
    CONSTRAINT rides_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['CASH'::character varying, 'CARD'::character varying, 'WALLET'::character varying])::text[])))
);


ALTER TABLE public.rides OWNER TO postgres;

--
-- Name: rides_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rides_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rides_id_seq OWNER TO postgres;

--
-- Name: rides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rides_id_seq OWNED BY public.rides.id;


--
-- Name: scheduled_rides; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduled_rides (
    id bigint NOT NULL,
    cancellation_reason character varying(255),
    cancelled_at timestamp(6) without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    dropoff_address character varying(255) NOT NULL,
    dropoff_latitude double precision NOT NULL,
    dropoff_longitude double precision NOT NULL,
    estimated_distance double precision,
    estimated_duration bigint,
    estimated_fare numeric(38,2),
    pickup_address character varying(255) NOT NULL,
    pickup_latitude double precision NOT NULL,
    pickup_longitude double precision NOT NULL,
    ride_type character varying(255),
    scheduled_at timestamp(6) without time zone NOT NULL,
    status character varying(255) NOT NULL,
    rider_id bigint NOT NULL,
    arrived_at timestamp(6) without time zone,
    assigned_at timestamp(6) without time zone,
    expired_at timestamp(6) without time zone,
    pickup_code character varying(6),
    pickup_code_verified_at timestamp(6) without time zone,
    reminder_sent_at timestamp(6) without time zone,
    started_at timestamp(6) without time zone,
    version bigint,
    driver_id bigint,
    CONSTRAINT scheduled_rides_status_check CHECK (((status)::text = ANY ((ARRAY['SCHEDULED'::character varying, 'ASSIGNED'::character varying, 'DRIVER_ARRIVED'::character varying, 'STARTED'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying, 'EXPIRED'::character varying, 'PENDING'::character varying, 'ACTIVE'::character varying])::text[])))
);


ALTER TABLE public.scheduled_rides OWNER TO postgres;

--
-- Name: scheduled_rides_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scheduled_rides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scheduled_rides_id_seq OWNER TO postgres;

--
-- Name: scheduled_rides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scheduled_rides_id_seq OWNED BY public.scheduled_rides.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    device_token character varying(255),
    email character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    is_online boolean NOT NULL,
    is_verified boolean NOT NULL,
    password character varying(255) NOT NULL,
    username character varying(255),
    role character varying(50) DEFAULT 'RIDER'::character varying,
    country_code character varying(255),
    normalized_phone character varying(255),
    phone_number character varying(255),
    phone_verified boolean DEFAULT false NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: wallet_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wallet_transactions (
    id bigint NOT NULL,
    amount numeric(38,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    description character varying(255),
    type character varying(255) NOT NULL,
    ride_id bigint,
    user_id bigint NOT NULL
);


ALTER TABLE public.wallet_transactions OWNER TO postgres;

--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wallet_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallet_transactions_id_seq OWNER TO postgres;

--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wallet_transactions_id_seq OWNED BY public.wallet_transactions.id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wallets (
    id bigint NOT NULL,
    balance numeric(38,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(6) without time zone,
    user_id bigint NOT NULL
);


ALTER TABLE public.wallets OWNER TO postgres;

--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wallets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallets_id_seq OWNER TO postgres;

--
-- Name: wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wallets_id_seq OWNED BY public.wallets.id;


--
-- Name: driver_earnings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_earnings ALTER COLUMN id SET DEFAULT nextval('public.driver_earnings_id_seq'::regclass);


--
-- Name: driver_notification_queue id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_notification_queue ALTER COLUMN id SET DEFAULT nextval('public.driver_notification_queue_id_seq'::regclass);


--
-- Name: driver_profiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_profiles ALTER COLUMN id SET DEFAULT nextval('public.driver_profiles_id_seq'::regclass);


--
-- Name: game_rooms id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_rooms ALTER COLUMN id SET DEFAULT nextval('public.game_rooms_id_seq'::regclass);


--
-- Name: location_updates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_updates ALTER COLUMN id SET DEFAULT nextval('public.location_updates_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: otp_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_codes ALTER COLUMN id SET DEFAULT nextval('public.otp_codes_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: profile_photos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_photos ALTER COLUMN id SET DEFAULT nextval('public.profile_photos_id_seq'::regclass);


--
-- Name: ratings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings ALTER COLUMN id SET DEFAULT nextval('public.ratings_id_seq'::regclass);


--
-- Name: ride_audit_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ride_audit_events ALTER COLUMN id SET DEFAULT nextval('public.ride_audit_events_id_seq'::regclass);


--
-- Name: ride_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ride_events ALTER COLUMN id SET DEFAULT nextval('public.ride_events_id_seq'::regclass);


--
-- Name: rides id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rides ALTER COLUMN id SET DEFAULT nextval('public.rides_id_seq'::regclass);


--
-- Name: scheduled_rides id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_rides ALTER COLUMN id SET DEFAULT nextval('public.scheduled_rides_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: wallet_transactions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions ALTER COLUMN id SET DEFAULT nextval('public.wallet_transactions_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Data for Name: driver_earnings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.driver_earnings (id, app_fee, created_at, gross_amount, net_amount, status, driver_id, ride_id) FROM stdin;
1	0.39	2026-06-29 15:01:16.151934	2.57	2.18	CONFIRMED	7	156
2	0.39	2026-06-29 15:15:45.966732	2.57	2.18	CONFIRMED	7	157
3	1.44	2026-06-30 09:56:02.780038	9.59	8.15	CONFIRMED	7	159
4	0.32	2026-06-30 21:11:14.712605	2.15	1.83	CONFIRMED	7	169
5	0.32	2026-06-30 21:16:38.690863	2.11	1.79	CONFIRMED	7	170
6	0.32	2026-07-01 19:33:32.769386	2.11	1.79	CONFIRMED	7	172
7	0.32	2026-07-02 20:52:09.508158	2.12	1.80	CONFIRMED	7	174
8	0.50	2026-07-03 18:27:46.119203	3.34	2.84	CONFIRMED	7	179
12	0.93	2026-07-07 00:09:20.332862	6.17	5.24	CONFIRMED	7	197
13	0.44	2026-07-07 10:02:02.991894	2.94	2.50	CONFIRMED	7	198
14	0.44	2026-07-09 00:04:19.454914	2.94	2.50	CONFIRMED	7	206
15	0.44	2026-07-09 15:56:10.42358	2.94	2.50	CONFIRMED	13	209
16	0.44	2026-07-09 16:00:49.61001	2.94	2.50	CONFIRMED	13	211
17	0.44	2026-07-09 21:42:52.103908	2.94	2.50	CONFIRMED	13	212
18	0.57	2026-07-09 22:44:06.485072	3.81	3.24	CONFIRMED	13	213
19	0.32	2026-07-10 17:22:24.10432	2.11	1.79	CONFIRMED	13	214
20	0.32	2026-07-10 17:24:29.406502	2.11	1.79	CONFIRMED	13	215
21	1.73	2026-07-10 19:25:00.720097	11.55	9.82	CONFIRMED	13	217
\.


--
-- Data for Name: driver_notification_queue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.driver_notification_queue (id, driver_id, driver_name, notified_at, queue_order, responded_at, ride_id, status) FROM stdin;
1	13	muasi	2026-06-21 15:41:20.24789	0	2026-06-21 15:41:32.480258	127	SKIPPED
2	13	muasi	2026-06-21 15:46:11.940022	0	2026-06-21 15:46:16.407619	128	ACCEPTED
4	13	muasi	2026-06-21 21:42:12.321199	0	2026-06-21 21:42:19.15177	129	SKIPPED
5	13	muasi	2026-06-21 21:43:55.231919	0	2026-06-21 21:44:00.514802	130	ACCEPTED
6	13	muasi	2026-06-21 21:58:53.358526	0	2026-06-21 21:59:03.086562	131	SKIPPED
\.


--
-- Data for Name: driver_profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.driver_profiles (id, user_id, license_number, vehicle_number, vehicle_type, vehicle_model, vehicle_color, is_verified, is_active, average_rating, total_rides, current_latitude, current_longitude, is_online, created_at, verified_at, last_seen_at) FROM stdin;
1	5	DL123456789	ABC-1234	CAR	Toyota Camry	White	f	f	5	0	\N	\N	f	2026-05-11 11:02:27.204671	\N	\N
3	10	12345	12345	CAR	12346	white	f	f	5	0	\N	\N	f	2026-05-14 11:51:45.143531	\N	\N
5	14	33445	44332156	CAR	2021	grey	t	f	5	0	26.3785809	50.1213397	f	2026-07-06 16:24:55.49615	\N	2026-07-06 21:50:17.643443
4	13	dl55654	hhgfyt5	CAR	any1	blue	t	f	5	5	26.398337087694458	50.14484851575251	f	2026-06-19 21:19:21.910982	\N	2026-07-13 09:37:34.726403
2	7	123456	123456	CAR	2026	yellow	f	f	5	7	26.398338065152743	50.14483812760206	f	2026-05-11 16:40:35.269427	\N	2026-07-13 15:44:06.444094
\.


--
-- Data for Name: game_rooms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_rooms (id, board_state, created_at, current_turn, finished_at, game_status, player1id, player1symbol, player2id, player2symbol, winner) FROM stdin;
\.


--
-- Data for Name: location_updates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.location_updates (id, user_id, ride_id, latitude, longitude, updated_at) FROM stdin;
151	7	140	26.37835797884888	50.12223287803808	2026-06-22 21:43:30.549838
152	7	140	26.378106820654224	50.1223028868119	2026-06-22 21:43:53.636422
153	7	140	26.37835797884888	50.12223287803808	2026-06-22 21:44:05.35653
154	7	140	26.37842310016309	50.12199417879055	2026-06-22 21:44:17.184204
155	7	140	26.378106820654224	50.1223028868119	2026-06-22 21:44:28.784993
156	7	140	26.37834535279073	50.12226504744369	2026-06-22 21:45:09.19304
157	7	140	26.378057543021587	50.12236760988611	2026-06-22 21:45:32.679076
158	7	140	26.378375279233328	50.121975664697466	2026-06-22 21:45:56.188333
159	7	140	26.37843499106618	50.12214681829695	2026-06-22 21:46:07.381584
160	7	141	26.3787125	50.1220815	2026-06-22 21:52:31.972053
161	7	141	26.37834535279073	50.12226504744369	2026-06-22 21:52:37.767804
162	7	141	26.37835797884888	50.12223287803808	2026-06-22 21:53:11.44241
163	7	141	26.37843499106618	50.12214681829695	2026-06-22 21:53:34.460159
164	7	141	26.378370851195516	50.12226592177626	2026-06-22 21:53:46.499567
165	7	146	26.3978896	50.1451298	2026-06-28 14:22:36.636163
166	7	147	26.3794839	50.1168727	2026-06-28 23:11:03.084159
167	7	148	26.379833	50.1211752	2026-06-28 23:13:24.283816
168	7	148	26.3794112	50.1213075	2026-06-28 23:13:35.109138
169	7	148	26.3792159	50.1213655	2026-06-28 23:13:40.135187
170	7	148	26.3790146	50.1214164	2026-06-28 23:13:45.065226
171	7	148	26.3788488	50.1214724	2026-06-28 23:13:50.052537
172	7	148	26.3786826	50.121514	2026-06-28 23:13:55.129101
173	7	148	26.3766839	50.121284	2026-06-28 23:16:12.864228
174	7	148	26.3767557	50.1207883	2026-06-28 23:16:16.725994
175	7	148	26.37683	50.1203252	2026-06-28 23:16:21.758932
176	7	148	26.37688	50.1198908	2026-06-28 23:16:26.994021
177	7	148	26.3769063	50.1196176	2026-06-28 23:16:31.663996
178	7	148	26.3767548	50.1194551	2026-06-28 23:16:36.71998
179	7	148	26.3765367	50.1194206	2026-06-28 23:16:41.71675
180	7	148	26.3763357	50.1193601	2026-06-28 23:16:46.814635
181	7	148	26.3761432	50.119367	2026-06-28 23:16:51.711607
182	7	148	26.3759118	50.1193197	2026-06-28 23:16:56.74021
183	7	148	26.3757162	50.1192647	2026-06-28 23:17:01.689168
184	7	148	26.375567	50.1191987	2026-06-28 23:17:06.731423
185	7	148	26.3754713	50.1191946	2026-06-28 23:17:12.699563
186	7	148	26.375288	50.1191822	2026-06-28 23:17:22.785364
187	7	150	26.398280063493118	50.14483101368386	2026-06-29 14:20:52.692566
188	7	150	26.398280063493118	50.14483101368386	2026-06-29 14:21:22.068634
189	7	150	26.398280063493118	50.14483101368386	2026-06-29 14:21:57.933514
190	7	150	26.39832973042919	50.144826023497856	2026-06-29 14:22:09.962678
191	7	150	26.398277269139697	50.14483566199684	2026-06-29 14:22:21.747236
192	7	150	26.398280063493118	50.14483101368386	2026-06-29 14:22:45.60026
193	7	150	26.39832973042919	50.144826023497856	2026-06-29 14:22:57.529026
194	7	150	26.398280063493118	50.14483101368386	2026-06-29 14:23:09.360963
195	7	150	26.39811166666667	50.14484166666667	2026-06-29 14:23:57.046212
196	7	150	26.39832973042919	50.144826023497856	2026-06-29 14:24:21.404318
197	7	150	26.398146392620365	50.14483499832281	2026-06-29 14:24:33.43979
198	7	150	26.398146392620365	50.14483499832281	2026-06-29 14:24:41.853953
199	7	150	26.398277269139697	50.14483566199684	2026-06-29 14:24:44.862153
200	7	150	26.398280063493118	50.14483101368386	2026-06-29 14:24:56.602929
201	7	150	26.398146392620365	50.14483499832281	2026-06-29 14:25:08.490592
202	7	150	26.398280063493118	50.14483101368386	2026-06-29 14:31:49.681331
203	7	150	26.398280063493118	50.14483101368386	2026-06-29 14:32:13.747987
204	7	151	26.3983388053528	50.14483109570154	2026-06-29 14:43:17.336658
205	7	151	26.398277269139697	50.14483566199684	2026-06-29 14:43:29.396845
206	7	151	26.398280063493118	50.14483101368386	2026-06-29 14:43:41.449368
207	7	151	26.398280063493118	50.14483101368386	2026-06-29 14:46:26.621105
208	7	153	26.398280063493118	50.14483101368386	2026-06-29 14:52:16.134068
209	7	159	26.398280063493118	50.14483101368386	2026-06-30 09:52:36.134984
210	7	159	26.39811166666667	50.14484166666667	2026-06-30 09:53:47.640352
211	7	159	26.398280063493118	50.14483101368386	2026-06-30 09:53:59.66878
212	7	159	26.398280063493118	50.14483101368386	2026-06-30 09:55:10.556435
213	7	159	26.398280063493118	50.14483101368386	2026-06-30 09:55:30.512541
214	7	160	26.3979001	50.1451758	2026-06-30 10:00:29.000412
215	7	160	26.3978157	50.1452792	2026-06-30 10:01:17.286191
216	7	162	26.3978394	50.145155	2026-06-30 11:30:43.730397
217	7	162	26.3977995	50.1452173	2026-06-30 11:31:55.979874
218	7	163	26.3983388053528	50.14483109570154	2026-06-30 11:33:32.721929
219	7	164	26.398158751230064	50.14483721830225	2026-06-30 11:44:10.115622
220	7	165	26.397772	50.1451225	2026-06-30 16:01:31.629102
221	7	166	26.3978143	50.1452478	2026-06-30 16:04:57.826268
222	7	168	26.3977508	50.1452249	2026-06-30 16:30:25.353738
223	7	169	26.3794571	50.1167756	2026-06-30 21:02:51.3385
224	7	169	26.3794571	50.1167756	2026-06-30 21:02:56.309221
225	7	169	26.3794436	50.116747	2026-06-30 21:03:01.219447
226	7	169	26.379368	50.1167339	2026-06-30 21:03:03.729109
227	7	169	26.3793395	50.1167996	2026-06-30 21:03:06.300612
228	7	169	26.3793807	50.1170152	2026-06-30 21:03:08.755939
229	7	169	26.3794104	50.1171929	2026-06-30 21:03:11.302456
230	7	169	26.3794767	50.1174934	2026-06-30 21:03:13.896138
231	7	169	26.3795236	50.1177157	2026-06-30 21:03:16.305221
232	7	169	26.3795898	50.1180672	2026-06-30 21:03:18.946287
233	7	169	26.3796291	50.1183212	2026-06-30 21:03:21.287934
234	7	169	26.3796895	50.1186721	2026-06-30 21:03:23.791438
235	7	169	26.3797091	50.1188045	2026-06-30 21:03:26.775044
236	7	169	26.3797334	50.1189295	2026-06-30 21:03:28.696408
237	7	169	26.3797553	50.1190616	2026-06-30 21:03:31.379095
238	7	169	26.3797838	50.1193302	2026-06-30 21:03:33.874855
239	7	169	26.3798132	50.1195194	2026-06-30 21:03:36.23926
240	7	169	26.3798572	50.119815	2026-06-30 21:03:38.873106
241	7	169	26.3798921	50.1200159	2026-06-30 21:03:41.356299
242	7	169	26.3799207	50.1202197	2026-06-30 21:03:43.700375
243	7	169	26.3799413	50.1203025	2026-06-30 21:03:46.33317
244	7	169	26.3799687	50.1204901	2026-06-30 21:03:48.764347
245	7	169	26.3800119	50.1206455	2026-06-30 21:03:51.296898
246	7	169	26.3800607	50.1209035	2026-06-30 21:03:53.740635
247	7	169	26.3800733	50.1210397	2026-06-30 21:03:56.229527
248	7	169	26.3799543	50.1211521	2026-06-30 21:03:58.835296
249	7	169	26.3798269	50.1211745	2026-06-30 21:04:01.316773
250	7	169	26.379632	50.1212247	2026-06-30 21:04:03.693145
251	7	169	26.3795192	50.1212499	2026-06-30 21:04:06.359115
252	7	169	26.3793528	50.1212916	2026-06-30 21:04:08.880819
253	7	169	26.3792329	50.121328	2026-06-30 21:04:11.384587
254	7	169	26.379046	50.1213706	2026-06-30 21:04:13.871893
255	7	169	26.378925	50.1214018	2026-06-30 21:04:16.378025
256	7	169	26.3786653	50.1214622	2026-06-30 21:04:21.297959
257	7	169	26.3785306	50.121489	2026-06-30 21:04:23.928439
258	7	169	26.3784766	50.1215008	2026-06-30 21:04:26.277039
260	7	169	26.3784499	50.121514	2026-06-30 21:04:36.221756
262	7	169	26.3784499	50.121514	2026-06-30 21:04:46.245571
263	7	169	26.3784499	50.121514	2026-06-30 21:04:51.459702
259	7	169	26.3784499	50.121514	2026-06-30 21:04:31.179205
261	7	169	26.3784499	50.121514	2026-06-30 21:04:41.278958
264	7	169	26.3784412	50.1215287	2026-06-30 21:06:30.717203
265	7	169	26.3784369	50.1215305	2026-06-30 21:08:23.574887
266	7	169	26.3784373	50.1215292	2026-06-30 21:08:28.483412
267	7	169	26.3784366	50.1215307	2026-06-30 21:08:33.664011
268	7	169	26.3784298	50.1215355	2026-06-30 21:08:38.681851
269	7	169	26.3783505	50.1215577	2026-06-30 21:08:43.66739
270	7	169	26.3783616	50.1215544	2026-06-30 21:08:43.845432
271	7	169	26.3782999	50.1215706	2026-06-30 21:08:48.502122
272	7	169	26.3782817	50.1215871	2026-06-30 21:08:53.542362
273	7	169	26.378286	50.1215853	2026-06-30 21:08:58.554277
274	7	169	26.3782868	50.121586	2026-06-30 21:09:03.440445
275	7	169	26.3782849	50.1215852	2026-06-30 21:09:08.48755
276	7	169	26.3782623	50.1215887	2026-06-30 21:09:11.410007
277	7	169	26.3782291	50.1215963	2026-06-30 21:09:13.503735
278	7	169	26.3781337	50.1216396	2026-06-30 21:09:16.724596
279	7	169	26.3780858	50.121665	2026-06-30 21:09:18.491622
280	7	169	26.3778643	50.1217477	2026-06-30 21:09:21.827364
281	7	169	26.377807	50.1217675	2026-06-30 21:09:23.536189
282	7	169	26.3775609	50.121834	2026-06-30 21:09:26.829854
283	7	169	26.3775055	50.1218559	2026-06-30 21:09:28.50839
284	7	169	26.3772811	50.1219182	2026-06-30 21:09:31.698699
285	7	169	26.377232	50.1219433	2026-06-30 21:09:33.507786
286	7	169	26.3770033	50.1219918	2026-06-30 21:09:36.737645
287	7	169	26.3769434	50.1220001	2026-06-30 21:09:38.524508
288	7	169	26.3767466	50.1220074	2026-06-30 21:09:41.758149
289	7	169	26.3767079	50.1220157	2026-06-30 21:09:43.841335
290	7	169	26.376589	50.1220322	2026-06-30 21:09:46.892149
291	7	169	26.3765768	50.1220198	2026-06-30 21:09:48.522454
292	7	169	26.3765712	50.121874	2026-06-30 21:09:51.735182
293	7	169	26.3765743	50.1218266	2026-06-30 21:09:53.469487
294	7	169	26.3766286	50.121577	2026-06-30 21:09:56.842753
295	7	169	26.3766362	50.1215094	2026-06-30 21:09:58.539521
296	7	169	26.376681	50.1212403	2026-06-30 21:10:01.762239
297	7	169	26.3766882	50.1211688	2026-06-30 21:10:03.487157
298	7	169	26.3767285	50.1208359	2026-06-30 21:10:06.905154
299	7	169	26.3767434	50.1207376	2026-06-30 21:10:08.528669
300	7	169	26.3768286	50.1202955	2026-06-30 21:10:11.697821
301	7	169	26.3768509	50.1201866	2026-06-30 21:10:13.443317
302	7	169	26.3769229	50.1198076	2026-06-30 21:10:16.736285
303	7	169	26.376934	50.1197181	2026-06-30 21:10:18.543306
304	7	169	26.3769834	50.1193931	2026-06-30 21:10:21.603588
305	7	169	26.376994	50.1193069	2026-06-30 21:10:23.508002
306	7	169	26.3770705	50.1189618	2026-06-30 21:10:26.711196
307	7	169	26.3770874	50.1188783	2026-06-30 21:10:28.489844
308	7	169	26.3771551	50.1185648	2026-06-30 21:10:31.918321
309	7	169	26.3771711	50.1184923	2026-06-30 21:10:33.516193
310	7	169	26.3772261	50.1182018	2026-06-30 21:10:36.714371
311	7	169	26.3772376	50.1181317	2026-06-30 21:10:38.557885
312	7	169	26.3772849	50.1178562	2026-06-30 21:10:41.668316
313	7	169	26.3772938	50.1177903	2026-06-30 21:10:43.548658
314	7	169	26.3773377	50.1175374	2026-06-30 21:10:46.880684
315	7	169	26.3773524	50.1174802	2026-06-30 21:10:48.571898
316	7	169	26.3773918	50.1173115	2026-06-30 21:10:51.619969
317	7	169	26.3773918	50.1173115	2026-06-30 21:10:53.590126
318	7	169	26.377399	50.1172242	2026-06-30 21:10:58.473086
319	7	169	26.3773976	50.1172172	2026-06-30 21:11:03.50967
320	7	169	26.3773976	50.1172172	2026-06-30 21:11:08.487372
321	7	169	26.3773976	50.1172172	2026-06-30 21:11:13.528015
322	7	170	26.3774543	50.1169108	2026-06-30 21:14:11.853255
323	7	170	26.377556	50.1167156	2026-06-30 21:14:16.651362
324	7	170	26.3778009	50.1167164	2026-06-30 21:14:21.795874
325	7	170	26.3780876	50.1166893	2026-06-30 21:14:26.626746
326	7	170	26.3783495	50.1166732	2026-06-30 21:14:31.679972
327	7	170	26.3785795	50.1166606	2026-06-30 21:14:36.671433
328	7	170	26.3787941	50.1166545	2026-06-30 21:14:41.833142
329	7	170	26.3790654	50.1166108	2026-06-30 21:15:11.821384
330	7	170	26.3793019	50.1166513	2026-06-30 21:15:16.731448
331	7	170	26.3793799	50.1169511	2026-06-30 21:15:21.673003
332	7	170	26.3794426	50.1173042	2026-06-30 21:15:26.818317
333	7	170	26.3795069	50.1176639	2026-06-30 21:15:31.666231
334	7	170	26.3795556	50.1180607	2026-06-30 21:15:36.746305
335	7	170	26.3796333	50.1184814	2026-06-30 21:15:41.945814
336	7	170	26.3796978	50.1188193	2026-06-30 21:15:47.77697
337	7	170	26.3796978	50.1188193	2026-06-30 21:15:47.985103
338	7	170	26.3797135	50.1189088	2026-06-30 21:15:52.483945
339	7	170	26.3797174	50.1189334	2026-06-30 21:15:52.655433
340	7	170	26.3797414	50.1190723	2026-06-30 21:15:57.490814
341	7	170	26.3797518	50.1191307	2026-06-30 21:15:57.667572
342	7	170	26.3797974	50.1193899	2026-06-30 21:16:02.467127
343	7	170	26.3798104	50.1194521	2026-06-30 21:16:02.65327
344	7	170	26.3798496	50.1197143	2026-06-30 21:16:07.469529
345	7	170	26.3798607	50.1197843	2026-06-30 21:16:07.632659
346	7	170	26.3799052	50.1200595	2026-06-30 21:16:12.575646
347	7	170	26.3799127	50.1201206	2026-06-30 21:16:12.751183
348	7	170	26.3799323	50.1202788	2026-06-30 21:16:17.473346
349	7	170	26.3799383	50.120316	2026-06-30 21:16:17.6675
350	7	170	26.3799542	50.1205051	2026-06-30 21:16:22.473107
351	7	170	26.3799616	50.1205579	2026-06-30 21:16:22.667547
352	7	170	26.3799744	50.1206589	2026-06-30 21:16:27.96954
353	7	170	26.37998	50.1206638	2026-06-30 21:16:29.019505
354	7	170	26.37998	50.1206638	2026-06-30 21:16:32.447004
355	7	170	26.3799608	50.1206823	2026-06-30 21:16:37.44871
356	7	171	26.37868026273919	50.121694291057175	2026-07-01 16:31:58.609696
357	7	171	26.378773176135848	50.12166269128222	2026-07-01 16:35:34.48859
359	7	172	26.378812725009805	50.12231622778924	2026-07-01 19:28:55.067915
358	7	172	26.37872971746836	50.12190889534948	2026-07-01 19:28:55.050214
360	7	172	26.378762111381146	50.12208335886768	2026-07-01 19:29:14.660055
361	7	172	26.378795469252438	50.12229016171302	2026-07-01 19:29:16.146166
362	7	172	26.37868242905002	50.12166378122022	2026-07-01 19:29:23.054747
363	7	172	26.37868242905002	50.12166378122022	2026-07-01 19:29:24.515149
364	7	172	26.37868242905002	50.12166378122022	2026-07-01 19:29:24.555636
365	7	172	26.378710762705975	50.12181986156878	2026-07-01 19:29:24.998213
366	7	173	26.3794466	50.1172015	2026-07-01 21:57:18.499578
367	7	173	26.3794465	50.1172023	2026-07-01 21:57:27.980205
368	7	173	26.3794619	50.1173045	2026-07-01 21:57:30.420889
369	7	173	26.3794615	50.1173136	2026-07-01 21:57:32.948925
370	7	173	26.3794816	50.117476	2026-07-01 21:57:37.378971
372	7	173	26.3795798	50.1179402	2026-07-01 21:57:42.546152
373	7	173	26.3795798	50.1179402	2026-07-01 21:57:42.829288
374	7	173	26.3797074	50.1185534	2026-07-01 21:57:47.414423
376	7	173	26.3797664	50.1188865	2026-07-01 21:57:52.380401
379	7	173	26.3798125	50.1192078	2026-07-01 21:57:57.889771
380	7	173	26.3799048	50.1197157	2026-07-01 21:58:02.440089
371	7	173	26.3794816	50.117476	2026-07-01 21:57:37.78302
375	7	173	26.3797074	50.1185534	2026-07-01 21:57:47.890805
377	7	173	26.3797664	50.1188865	2026-07-01 21:57:52.849748
378	7	173	26.3798125	50.1192078	2026-07-01 21:57:57.425101
381	7	173	26.3799048	50.1197157	2026-07-01 21:58:02.943029
382	7	173	26.3799787	50.1201859	2026-07-01 21:58:07.881536
383	7	174	26.3795501	50.117335	2026-07-02 20:42:41.068719
384	7	174	26.3795501	50.117335	2026-07-02 20:42:42.463508
385	7	174	26.3794602	50.117335	2026-07-02 20:42:47.604321
386	7	174	26.3794452	50.1173991	2026-07-02 20:42:47.909225
387	7	174	26.379478	50.1175893	2026-07-02 20:42:52.512321
388	7	174	26.3794916	50.1176585	2026-07-02 20:42:52.927725
389	7	174	26.37956	50.1180088	2026-07-02 20:42:57.5101
390	7	174	26.3795798	50.1181081	2026-07-02 20:42:57.848585
391	7	174	26.3796658	50.1185372	2026-07-02 20:43:02.506832
392	7	174	26.3796871	50.1186402	2026-07-02 20:43:02.951686
393	7	174	26.3797296	50.1188904	2026-07-02 20:43:07.542555
394	7	174	26.3797367	50.1189286	2026-07-02 20:43:08.058335
395	7	174	26.3797887	50.1191791	2026-07-02 20:43:12.525678
396	7	174	26.3797991	50.1192678	2026-07-02 20:43:12.844117
397	7	174	26.3798548	50.1196019	2026-07-02 20:43:17.525421
398	7	174	26.3798611	50.1196594	2026-07-02 20:43:17.885153
399	7	174	26.3799088	50.1197799	2026-07-02 20:43:22.546301
400	7	174	26.3799225	50.1198424	2026-07-02 20:43:23.13543
401	7	174	26.3799536	50.120104	2026-07-02 20:43:27.542367
402	7	174	26.3799578	50.1201629	2026-07-02 20:43:27.985422
403	7	174	26.3799705	50.1203643	2026-07-02 20:43:32.548352
404	7	174	26.3799705	50.1203643	2026-07-02 20:43:32.69877
405	7	174	26.3800058	50.1206404	2026-07-02 20:43:37.582156
406	7	174	26.3800181	50.12071	2026-07-02 20:43:37.953947
407	7	174	26.3800613	50.1209659	2026-07-02 20:43:42.47514
408	7	174	26.3800718	50.1210157	2026-07-02 20:43:42.922192
409	7	174	26.3799974	50.121136	2026-07-02 20:43:47.537425
410	7	174	26.3799487	50.1211434	2026-07-02 20:43:47.959352
411	7	174	26.3797253	50.121203	2026-07-02 20:43:52.544817
412	7	174	26.3796707	50.1212221	2026-07-02 20:43:52.896216
413	7	174	26.3794551	50.1212876	2026-07-02 20:43:57.531168
414	7	174	26.3794026	50.1212944	2026-07-02 20:43:57.955894
415	7	174	26.3792608	50.1213028	2026-07-02 20:44:02.480398
416	7	174	26.3791996	50.1213061	2026-07-02 20:44:02.882552
417	7	174	26.3789905	50.1213733	2026-07-02 20:44:07.469612
418	7	174	26.3789378	50.1213811	2026-07-02 20:44:08.04405
419	7	174	26.378807	50.1214306	2026-07-02 20:44:12.449222
420	7	174	26.3786169	50.1214847	2026-07-02 20:44:16.095109
421	7	174	26.3784987	50.1215194	2026-07-02 20:44:20.934184
422	7	174	26.3783721	50.1215182	2026-07-02 20:44:31.340721
423	7	174	26.3784115	50.1214246	2026-07-02 20:46:53.192415
424	7	174	26.3783383	50.1213562	2026-07-02 20:48:13.368062
425	7	174	26.3783547	50.121407	2026-07-02 20:50:14.553173
426	7	174	26.3783626	50.1214864	2026-07-02 20:50:17.909537
427	7	174	26.3783774	50.1215028	2026-07-02 20:50:19.706067
428	7	174	26.3783359	50.1215964	2026-07-02 20:50:24.026406
429	7	174	26.3783359	50.1215964	2026-07-02 20:50:24.026406
430	7	174	26.3781981	50.1216467	2026-07-02 20:50:29.04037
431	7	174	26.3781981	50.1216467	2026-07-02 20:50:29.043559
432	7	174	26.3780508	50.1216829	2026-07-02 20:50:33.916732
433	7	174	26.3780508	50.1216829	2026-07-02 20:50:33.927088
434	7	174	26.3778709	50.1217479	2026-07-02 20:50:38.89198
435	7	174	26.3778709	50.1217479	2026-07-02 20:50:39.068199
436	7	174	26.3777233	50.1218078	2026-07-02 20:50:43.912482
437	7	174	26.3777233	50.1218078	2026-07-02 20:50:43.956206
438	7	174	26.3775681	50.1218597	2026-07-02 20:50:48.953903
439	7	174	26.3775681	50.1218597	2026-07-02 20:50:49.126007
440	7	174	26.3773693	50.1219053	2026-07-02 20:50:54.09093
441	7	174	26.3773693	50.1219053	2026-07-02 20:50:54.09093
442	7	174	26.3771643	50.1219459	2026-07-02 20:50:58.893283
443	7	174	26.3771643	50.1219459	2026-07-02 20:50:59.075514
444	7	174	26.3769641	50.1220013	2026-07-02 20:51:03.906731
445	7	174	26.3769641	50.1220013	2026-07-02 20:51:04.158896
446	7	174	26.3767724	50.1220463	2026-07-02 20:51:09.046392
447	7	174	26.3767724	50.1220463	2026-07-02 20:51:09.207754
448	7	174	26.3766439	50.1220855	2026-07-02 20:51:14.126499
449	7	174	26.3766439	50.1220855	2026-07-02 20:51:14.180649
450	7	174	26.3765908	50.122069	2026-07-02 20:51:18.978957
451	7	174	26.3765728	50.1220186	2026-07-02 20:51:22.038728
452	7	174	26.3765871	50.1219457	2026-07-02 20:51:23.983421
453	7	174	26.3766031	50.1216914	2026-07-02 20:51:26.878507
454	7	174	26.3766248	50.1215506	2026-07-02 20:51:28.99094
455	7	174	26.3766677	50.1212801	2026-07-02 20:51:32.076278
456	7	174	26.3767008	50.1211007	2026-07-02 20:51:33.987987
457	7	174	26.3767473	50.1208221	2026-07-02 20:51:36.826542
458	7	174	26.3767721	50.1206253	2026-07-02 20:51:38.95414
459	7	174	26.3768177	50.1203485	2026-07-02 20:51:41.862861
460	7	174	26.3768613	50.1201672	2026-07-02 20:51:43.948507
461	7	174	26.376907	50.119911	2026-07-02 20:51:47.093731
462	7	174	26.3769251	50.1197408	2026-07-02 20:51:48.968908
463	7	174	26.3769737	50.1195573	2026-07-02 20:51:51.899244
464	7	174	26.3770218	50.1195183	2026-07-02 20:51:53.955554
465	7	174	26.3771244	50.1195387	2026-07-02 20:51:56.899887
466	7	174	26.3771461	50.1195348	2026-07-02 20:51:58.931004
467	7	174	26.3772498	50.1195181	2026-07-02 20:52:03.97172
468	7	174	26.3772356	50.1195238	2026-07-02 20:52:08.951866
469	7	175	26.3952219	50.1177498	2026-07-02 21:29:40.842862
470	7	175	26.3944391	50.1179807	2026-07-02 21:29:45.871898
471	7	175	26.3944391	50.1179807	2026-07-02 21:29:50.794964
472	7	175	26.3936442	50.1182067	2026-07-02 21:29:51.156789
473	7	175	26.3929859	50.1183968	2026-07-02 21:29:55.614908
474	7	175	26.3928203	50.1184496	2026-07-02 21:29:55.79212
475	7	175	26.3921778	50.1186586	2026-07-02 21:30:00.530729
476	7	175	26.3920275	50.1187087	2026-07-02 21:30:00.872065
477	7	175	26.3914447	50.1188791	2026-07-02 21:30:05.505936
478	7	175	26.391292	50.1189213	2026-07-02 21:30:05.857393
479	7	175	26.3906645	50.1190993	2026-07-02 21:30:10.467899
480	7	175	26.3905003	50.1191416	2026-07-02 21:30:10.821941
481	7	175	26.3898081	50.1193454	2026-07-02 21:30:15.504081
482	7	175	26.3896295	50.1193965	2026-07-02 21:30:15.896595
483	7	175	26.3888875	50.1195969	2026-07-02 21:30:20.742463
484	7	175	26.3887045	50.1196518	2026-07-02 21:30:20.816478
485	7	175	26.3879615	50.1198762	2026-07-02 21:30:25.45454
486	7	175	26.3877787	50.1199322	2026-07-02 21:30:25.881252
487	7	175	26.3870585	50.1201407	2026-07-02 21:30:30.450058
489	7	175	26.3861855	50.1203873	2026-07-02 21:30:35.501231
490	7	175	26.3860139	50.1204358	2026-07-02 21:30:35.904987
492	7	175	26.3851836	50.1206789	2026-07-02 21:30:40.881952
495	7	175	26.3837448	50.1210277	2026-07-02 21:30:50.473147
496	7	175	26.3835872	50.121065	2026-07-02 21:30:51.087927
497	7	175	26.3829972	50.121221	2026-07-02 21:30:55.46387
499	7	175	26.3822424	50.1214321	2026-07-02 21:31:00.508442
501	7	175	26.3815069	50.1216471	2026-07-02 21:31:05.596251
504	7	175	26.3807138	50.1218826	2026-07-02 21:31:10.906773
505	7	175	26.380315	50.1219911	2026-07-02 21:31:15.479483
506	7	175	26.3802302	50.1219912	2026-07-02 21:31:15.859843
488	7	175	26.3868799	50.1201927	2026-07-02 21:30:31.053259
491	7	175	26.3853523	50.1206331	2026-07-02 21:30:40.501607
493	7	175	26.3843716	50.1208739	2026-07-02 21:30:45.842695
494	7	175	26.3845309	50.1208365	2026-07-02 21:30:46.01997
498	7	175	26.3828503	50.1212594	2026-07-02 21:30:55.877444
500	7	175	26.38209	50.1214774	2026-07-02 21:31:00.855351
502	7	175	26.3813686	50.1216869	2026-07-02 21:31:05.87762
503	7	175	26.3808414	50.1218484	2026-07-02 21:31:10.468924
507	7	175	26.3798924	50.122062	2026-07-02 21:31:20.509671
508	7	175	26.3798083	50.1220842	2026-07-02 21:31:20.865305
509	7	175	26.3794988	50.122155	2026-07-02 21:31:25.477135
510	7	175	26.3794247	50.1221791	2026-07-02 21:31:25.864733
511	7	175	26.3792027	50.1222392	2026-07-02 21:31:30.485782
512	7	175	26.3791633	50.1222483	2026-07-02 21:31:30.879483
513	7	175	26.3790023	50.1223078	2026-07-02 21:31:35.492861
514	7	175	26.3789536	50.1223148	2026-07-02 21:31:35.891041
515	7	175	26.3787501	50.1223904	2026-07-02 21:31:40.460373
516	7	175	26.3787168	50.122387	2026-07-02 21:31:41.469398
517	7	175	26.3786409	50.1222324	2026-07-02 21:31:45.529151
518	7	175	26.378629	50.1221695	2026-07-02 21:31:46.230102
519	7	175	26.3785526	50.1218774	2026-07-02 21:31:50.668624
520	7	175	26.3785378	50.1218033	2026-07-02 21:31:50.938777
521	7	175	26.3784968	50.1215854	2026-07-02 21:31:55.509018
522	7	175	26.3784773	50.1215525	2026-07-02 21:31:56.222079
523	7	175	26.3784309	50.1214484	2026-07-02 21:32:00.608788
524	7	175	26.3783832	50.1213076	2026-07-02 21:32:07.431305
525	7	175	26.3783877	50.1214234	2026-07-02 21:42:43.411384
526	7	175	26.3783488	50.1215744	2026-07-02 21:42:51.98541
527	7	175	26.3783153	50.1216848	2026-07-02 21:42:56.920222
528	7	175	26.3785975	50.1221639	2026-07-02 21:43:01.889162
529	7	175	26.378624	50.1222951	2026-07-02 21:43:06.829696
530	7	175	26.3786849	50.1224093	2026-07-02 21:43:31.895627
531	7	175	26.3786163	50.1225162	2026-07-02 21:43:37.141296
532	7	175	26.3783383	50.1223886	2026-07-02 21:43:41.931867
533	7	175	26.3779829	50.1225907	2026-07-02 21:43:47.06963
534	7	175	26.3775385	50.1227539	2026-07-02 21:43:52.043863
535	7	175	26.3770693	50.1229167	2026-07-02 21:43:57.111993
536	7	175	26.3765573	50.1230952	2026-07-02 21:44:01.875894
537	7	175	26.3759222	50.1233097	2026-07-02 21:44:06.918189
538	7	175	26.375228	50.1235193	2026-07-02 21:44:11.945527
539	7	175	26.3745751	50.1237298	2026-07-02 21:44:17.073877
540	7	175	26.3739941	50.1238963	2026-07-02 21:44:21.966562
541	7	175	26.3735774	50.1240675	2026-07-02 21:44:26.864558
542	7	175	26.3734275	50.1243771	2026-07-02 21:44:31.943411
543	7	175	26.3738443	50.12443	2026-07-02 21:44:36.901829
544	7	175	26.3743792	50.1243044	2026-07-02 21:44:41.852163
545	7	175	26.3749885	50.1241402	2026-07-02 21:44:47.025652
546	7	175	26.3757179	50.1239197	2026-07-02 21:44:51.859491
547	7	175	26.3765354	50.1236778	2026-07-02 21:44:56.881083
548	7	175	26.3774259	50.123401	2026-07-02 21:45:01.850001
549	7	175	26.3783942	50.1230973	2026-07-02 21:45:07.036154
550	7	175	26.3794055	50.1228083	2026-07-02 21:45:11.94742
551	7	175	26.3803937	50.122532	2026-07-02 21:45:16.903657
552	7	175	26.381331	50.1222152	2026-07-02 21:45:22.088799
553	7	175	26.382284	50.1219167	2026-07-02 21:45:26.883911
554	7	175	26.383187	50.121656	2026-07-02 21:45:31.933838
555	7	175	26.3840505	50.1213909	2026-07-02 21:45:36.914071
556	7	175	26.3849557	50.1210919	2026-07-02 21:45:42.043115
557	7	175	26.3858975	50.1207949	2026-07-02 21:45:46.851805
558	7	175	26.387259	50.1203751	2026-07-02 21:45:53.910869
559	7	175	26.3882632	50.1200773	2026-07-02 21:45:58.873662
560	7	175	26.389291	50.1197712	2026-07-02 21:46:03.822624
561	7	175	26.3903169	50.119473	2026-07-02 21:46:08.818054
562	7	175	26.3913252	50.1191827	2026-07-02 21:46:13.880409
563	7	175	26.3923407	50.1188781	2026-07-02 21:46:19.029125
564	7	175	26.3933557	50.1185756	2026-07-02 21:46:23.827995
565	7	175	26.3943654	50.118275	2026-07-02 21:46:28.790954
566	7	175	26.3953693	50.1179809	2026-07-02 21:46:33.897468
567	7	175	26.3967281	50.1175714	2026-07-02 21:46:40.801884
568	7	175	26.3976633	50.1172771	2026-07-02 21:46:45.875176
569	7	175	26.3985612	50.1169305	2026-07-02 21:46:51.299332
570	7	175	26.3995564	50.1165174	2026-07-02 21:46:56.992744
571	7	175	26.4002288	50.1162025	2026-07-02 21:47:01.868166
572	7	175	26.4007221	50.116006	2026-07-02 21:47:06.834929
573	7	175	26.4012287	50.115754	2026-07-02 21:47:12.079254
574	7	175	26.401723	50.1155032	2026-07-02 21:47:16.844344
575	7	175	26.4020073	50.1154252	2026-07-02 21:47:21.893767
576	7	175	26.4020577	50.1156602	2026-07-02 21:47:26.850574
577	7	175	26.4018493	50.1160124	2026-07-02 21:47:32.034609
578	7	175	26.4016602	50.1163926	2026-07-02 21:47:36.910232
579	7	175	26.4014821	50.1167323	2026-07-02 21:47:41.911434
580	7	175	26.4013284	50.1169573	2026-07-02 21:47:47.091992
581	7	175	26.4011863	50.1170411	2026-07-02 21:47:51.920898
582	7	175	26.4010742	50.1171257	2026-07-02 21:48:01.861602
583	7	175	26.4009884	50.1171695	2026-07-02 21:48:06.864612
584	7	176	26.3785562	50.121378	2026-07-03 00:16:24.669288
585	7	176	26.3785704	50.1213841	2026-07-03 00:16:46.254196
586	7	176	26.3785644	50.1213901	2026-07-03 00:16:51.685072
587	7	176	26.378567	50.1213804	2026-07-03 00:16:56.253949
588	7	176	26.3785661	50.1213805	2026-07-03 00:17:01.281056
589	7	176	26.3785568	50.1213745	2026-07-03 00:17:06.216438
590	7	176	26.378555	50.1213725	2026-07-03 00:17:11.632641
591	7	176	26.3785531	50.1213711	2026-07-03 00:17:16.489313
592	7	176	26.3785406	50.1213593	2026-07-03 00:17:21.618706
593	7	176	26.3785056	50.1213162	2026-07-03 00:18:06.826333
594	7	176	26.3785315	50.1213256	2026-07-03 00:18:07.508017
595	7	176	26.3785315	50.1213256	2026-07-03 00:18:07.597129
596	7	176	26.3784946	50.1212531	2026-07-03 00:18:07.717788
597	7	176	26.3784946	50.1212531	2026-07-03 00:18:08.022172
598	7	176	26.3784946	50.1212531	2026-07-03 00:18:08.028638
599	7	176	26.3784971	50.1212422	2026-07-03 00:18:11.671079
600	7	176	26.3785016	50.1212533	2026-07-03 00:18:16.759359
601	7	176	26.3785124	50.1212864	2026-07-03 00:18:23.728656
602	7	176	26.3785124	50.1212864	2026-07-03 00:18:27.157907
603	7	176	26.3784849	50.121359	2026-07-03 00:18:32.153993
604	7	176	26.3784849	50.121359	2026-07-03 00:18:32.266614
605	7	176	26.3784849	50.121359	2026-07-03 00:18:36.462875
606	7	176	26.3784541	50.1212624	2026-07-03 00:18:37.369397
608	7	176	26.3785017	50.1216117	2026-07-03 00:18:46.291205
610	7	176	26.3785533	50.1219463	2026-07-03 00:18:51.458205
614	7	176	26.3786571	50.1224346	2026-07-03 00:19:01.234086
615	7	176	26.3786586	50.1224368	2026-07-03 00:19:06.250636
616	7	176	26.3785511	50.1224622	2026-07-03 00:19:10.153952
620	7	176	26.3780933	50.1226129	2026-07-03 00:19:20.231812
621	7	176	26.3780232	50.1226399	2026-07-03 00:19:21.39056
622	7	176	26.3776629	50.1227571	2026-07-03 00:19:25.283226
623	7	176	26.3775604	50.1227897	2026-07-03 00:19:26.240277
625	7	176	26.3770372	50.122964	2026-07-03 00:19:31.232994
626	7	176	26.3765938	50.1230989	2026-07-03 00:19:35.922156
627	7	176	26.376477	50.1231434	2026-07-03 00:19:36.225022
628	7	176	26.3759636	50.1233122	2026-07-03 00:19:40.227133
629	7	176	26.3758249	50.1233546	2026-07-03 00:19:41.225472
630	7	176	26.3752353	50.1235443	2026-07-03 00:19:45.210893
631	7	176	26.3744685	50.1237743	2026-07-03 00:19:51.153963
634	7	176	26.3738303	50.1239651	2026-07-03 00:19:55.173759
636	7	176	26.3734519	50.1242271	2026-07-03 00:20:00.161485
637	7	176	26.3734313	50.1243054	2026-07-03 00:20:01.22892
643	7	176	26.3747765	50.124158	2026-07-03 00:20:16.265651
647	7	176	26.3762985	50.1237332	2026-07-03 00:20:26.214216
648	7	176	26.3769976	50.1235168	2026-07-03 00:20:30.287382
652	7	176	26.3788992	50.1229396	2026-07-03 00:20:40.544212
654	7	176	26.3798822	50.1226568	2026-07-03 00:20:45.49007
655	7	176	26.3800752	50.1226072	2026-07-03 00:20:46.57345
657	7	176	26.3810485	50.1223245	2026-07-03 00:20:51.599861
658	7	176	26.3818158	50.1220851	2026-07-03 00:20:55.482182
660	7	176	26.3827272	50.1217882	2026-07-03 00:21:00.51181
662	7	176	26.3835489	50.1215279	2026-07-03 00:21:05.50388
663	7	176	26.3837033	50.121477	2026-07-03 00:21:06.646452
664	7	176	26.384338	50.1212819	2026-07-03 00:21:10.609681
665	7	176	26.3844917	50.1212331	2026-07-03 00:21:11.635359
666	7	176	26.3851442	50.1210206	2026-07-03 00:21:15.56956
667	7	176	26.385314	50.1209612	2026-07-03 00:21:16.632844
668	7	176	26.3860257	50.1207267	2026-07-03 00:21:20.632168
669	7	176	26.3862141	50.1206679	2026-07-03 00:21:21.65896
670	7	176	26.3869579	50.1204402	2026-07-03 00:21:25.593418
671	7	176	26.3871423	50.1203866	2026-07-03 00:21:26.61942
673	7	176	26.3880358	50.1201047	2026-07-03 00:21:31.661788
674	7	176	26.3887939	50.1198737	2026-07-03 00:21:35.706683
675	7	176	26.3889865	50.1198204	2026-07-03 00:21:36.662112
677	7	176	26.3900104	50.1195605	2026-07-03 00:21:42.194806
678	7	176	26.3907968	50.1193324	2026-07-03 00:21:45.513319
681	7	176	26.39192	50.1190014	2026-07-03 00:21:51.703368
682	7	176	26.392678	50.1187756	2026-07-03 00:21:55.549087
683	7	176	26.3928659	50.1187176	2026-07-03 00:21:56.611864
684	7	176	26.3936288	50.118489	2026-07-03 00:22:00.641912
685	7	176	26.3938197	50.1184302	2026-07-03 00:22:01.6698
686	7	176	26.3945957	50.1182071	2026-07-03 00:22:05.656186
687	7	176	26.3947871	50.1181527	2026-07-03 00:22:06.603672
688	7	176	26.3955553	50.1179356	2026-07-03 00:22:10.577107
689	7	176	26.3957437	50.1178811	2026-07-03 00:22:11.610157
690	7	176	26.3964905	50.1176502	2026-07-03 00:22:15.613871
691	7	176	26.3966772	50.1175934	2026-07-03 00:22:16.665429
692	7	176	26.3973937	50.1173637	2026-07-03 00:22:20.617073
693	7	176	26.3975719	50.1173029	2026-07-03 00:22:21.83389
694	7	176	26.3982521	50.1170445	2026-07-03 00:22:25.535748
695	7	176	26.3984172	50.1169888	2026-07-03 00:22:26.627875
696	7	176	26.3990599	50.1167416	2026-07-03 00:22:30.698162
697	7	176	26.3992069	50.1166748	2026-07-03 00:22:31.664553
698	7	176	26.3997837	50.1164306	2026-07-03 00:22:35.533636
699	7	176	26.3999229	50.1163609	2026-07-03 00:22:36.656899
704	7	176	26.4015645	50.1155922	2026-07-03 00:22:50.535082
705	7	176	26.4016551	50.1155317	2026-07-03 00:22:51.632076
706	7	176	26.4019419	50.1154209	2026-07-03 00:22:55.576396
707	7	176	26.4019871	50.1154323	2026-07-03 00:22:56.699459
607	7	176	26.378438	50.1214539	2026-07-03 00:18:41.490175
609	7	176	26.3785182	50.1216496	2026-07-03 00:18:47.247074
611	7	176	26.3785653	50.1220286	2026-07-03 00:18:52.120975
612	7	176	26.3786307	50.1223348	2026-07-03 00:18:56.272021
613	7	176	26.3786436	50.122387	2026-07-03 00:18:57.147013
617	7	176	26.3785117	50.1224702	2026-07-03 00:19:11.258944
618	7	176	26.3783485	50.1225081	2026-07-03 00:19:15.174388
619	7	176	26.3783128	50.1225235	2026-07-03 00:19:16.314657
624	7	176	26.3771446	50.1229327	2026-07-03 00:19:31.012395
632	7	176	26.3750802	50.1235882	2026-07-03 00:19:51.432392
633	7	176	26.3743229	50.1238154	2026-07-03 00:19:51.46261
635	7	176	26.3737222	50.1240028	2026-07-03 00:19:56.242232
638	7	176	26.3735776	50.1245024	2026-07-03 00:20:05.539342
639	7	176	26.3736712	50.1244921	2026-07-03 00:20:06.303856
640	7	176	26.3740576	50.1243799	2026-07-03 00:20:10.474282
641	7	176	26.3741696	50.1243467	2026-07-03 00:20:11.304084
642	7	176	26.3746456	50.124191	2026-07-03 00:20:15.185553
644	7	176	26.3753336	50.1240081	2026-07-03 00:20:20.266072
645	7	176	26.3754855	50.1239701	2026-07-03 00:20:21.262232
646	7	176	26.3761318	50.1237847	2026-07-03 00:20:25.272693
649	7	176	26.3771803	50.1234576	2026-07-03 00:20:31.623559
650	7	176	26.3779341	50.1232268	2026-07-03 00:20:35.580215
651	7	176	26.3781237	50.1231742	2026-07-03 00:20:36.65618
653	7	176	26.3791038	50.1228729	2026-07-03 00:20:41.635064
656	7	176	26.3808534	50.122384	2026-07-03 00:20:50.560147
659	7	176	26.3820039	50.1220276	2026-07-03 00:20:56.632234
661	7	176	26.3829026	50.1217292	2026-07-03 00:21:01.641624
672	7	176	26.3878555	50.120169	2026-07-03 00:21:30.606702
676	7	176	26.3898051	50.1196117	2026-07-03 00:21:40.525914
679	7	176	26.390987	50.1192761	2026-07-03 00:21:46.616586
680	7	176	26.3917301	50.1190534	2026-07-03 00:21:50.531199
700	7	176	26.4004598	50.1161473	2026-07-03 00:22:40.661277
701	7	176	26.4005816	50.1160996	2026-07-03 00:22:41.691986
702	7	176	26.4010591	50.1158793	2026-07-03 00:22:45.57924
703	7	176	26.4011648	50.1158178	2026-07-03 00:22:46.618994
708	7	176	26.4020555	50.1156056	2026-07-03 00:23:00.49185
709	7	176	26.402029	50.1156701	2026-07-03 00:23:01.568043
710	7	176	26.4018718	50.1159515	2026-07-03 00:23:05.497978
711	7	176	26.4018299	50.1160363	2026-07-03 00:23:06.644412
712	7	176	26.4016535	50.1163761	2026-07-03 00:23:10.548151
713	7	176	26.4016129	50.1164531	2026-07-03 00:23:11.644652
714	7	176	26.4014703	50.116769	2026-07-03 00:23:15.717516
715	7	176	26.4014316	50.1168385	2026-07-03 00:23:16.679344
716	7	176	26.4013017	50.116999	2026-07-03 00:23:20.555236
717	7	176	26.4012718	50.1170264	2026-07-03 00:23:21.684312
718	7	176	26.4011914	50.1171026	2026-07-03 00:23:25.603438
719	7	177	26.4130666	50.1118523	2026-07-03 00:33:15.324996
720	7	177	26.4130666	50.1118523	2026-07-03 00:33:20.321626
721	7	177	26.4130666	50.1118523	2026-07-03 00:33:25.304458
722	7	177	26.4130666	50.1118523	2026-07-03 00:33:30.350174
723	7	177	26.4130666	50.1118523	2026-07-03 00:33:35.300805
724	7	177	26.4130666	50.1118523	2026-07-03 00:33:39.946337
725	7	177	26.4130666	50.1118523	2026-07-03 00:33:45.329274
726	7	177	26.4130666	50.1118523	2026-07-03 00:33:50.254271
727	7	177	26.4130666	50.1118523	2026-07-03 00:33:55.312798
728	7	177	26.4130666	50.1118523	2026-07-03 00:34:00.312938
729	7	177	26.4130666	50.1118523	2026-07-03 00:34:05.278141
730	7	177	26.4130666	50.1118523	2026-07-03 00:34:10.328552
731	7	177	26.4130666	50.1118523	2026-07-03 00:34:15.363169
732	7	177	26.4130666	50.1118523	2026-07-03 00:34:20.306318
733	7	177	26.4130666	50.1118523	2026-07-03 00:34:25.364345
734	7	177	26.4130666	50.1118523	2026-07-03 00:34:30.321049
735	7	177	26.4130666	50.1118523	2026-07-03 00:34:35.327891
736	7	177	26.4130666	50.1118523	2026-07-03 00:34:40.293602
737	7	177	26.4130678	50.1118531	2026-07-03 00:34:45.31397
738	7	177	26.4130917	50.111844	2026-07-03 00:34:50.298601
739	7	177	26.4131195	50.1118038	2026-07-03 00:34:53.526288
740	7	177	26.4131269	50.1117932	2026-07-03 00:34:55.259917
741	7	177	26.4132372	50.1117934	2026-07-03 00:34:59.651523
742	7	177	26.4132372	50.1117934	2026-07-03 00:35:00.240458
743	7	177	26.4134961	50.1119527	2026-07-03 00:35:04.522615
744	7	177	26.4134961	50.1119527	2026-07-03 00:35:05.267514
745	7	177	26.4137737	50.1121372	2026-07-03 00:35:09.510482
746	7	177	26.4137737	50.1121372	2026-07-03 00:35:10.271291
747	7	177	26.4138742	50.112314	2026-07-03 00:35:14.503792
748	7	177	26.4138742	50.112314	2026-07-03 00:35:15.277013
749	7	177	26.4137315	50.1125138	2026-07-03 00:35:19.472301
750	7	177	26.4137315	50.1125138	2026-07-03 00:35:20.265319
751	7	177	26.4136369	50.1126858	2026-07-03 00:35:24.496498
752	7	177	26.4136369	50.1126858	2026-07-03 00:35:25.278982
753	7	177	26.4135814	50.1127785	2026-07-03 00:35:29.486049
754	7	177	26.4135814	50.1127785	2026-07-03 00:35:30.290948
755	7	177	26.4134734	50.1130226	2026-07-03 00:35:34.574164
756	7	177	26.4134734	50.1130226	2026-07-03 00:35:35.315024
757	7	177	26.413352	50.1132393	2026-07-03 00:35:39.536826
758	7	177	26.413352	50.1132393	2026-07-03 00:35:40.306842
759	7	177	26.4132405	50.1134605	2026-07-03 00:35:44.499054
760	7	177	26.4132405	50.1134605	2026-07-03 00:35:45.30379
761	7	177	26.4130893	50.1137908	2026-07-03 00:35:49.484684
762	7	177	26.4130893	50.1137908	2026-07-03 00:35:50.263871
763	7	177	26.4129834	50.1140071	2026-07-03 00:35:54.208803
764	7	177	26.4129834	50.1140071	2026-07-03 00:35:55.506286
765	7	177	26.4128873	50.1141527	2026-07-03 00:35:59.569291
766	7	177	26.4128873	50.1141527	2026-07-03 00:36:00.529045
767	7	177	26.4127469	50.1144334	2026-07-03 00:36:04.579841
768	7	177	26.4127469	50.1144334	2026-07-03 00:36:05.383434
769	7	177	26.4125602	50.1147778	2026-07-03 00:36:09.654535
770	7	177	26.4125602	50.1147778	2026-07-03 00:36:10.358613
771	7	177	26.4124192	50.115112	2026-07-03 00:36:14.545932
772	7	177	26.4124192	50.115112	2026-07-03 00:36:15.371045
773	7	177	26.412294	50.115327	2026-07-03 00:36:19.654325
774	7	177	26.412294	50.115327	2026-07-03 00:36:20.617309
775	7	177	26.4121338	50.1155146	2026-07-03 00:36:24.625759
776	7	177	26.4121338	50.1155146	2026-07-03 00:36:25.38751
777	7	177	26.411917	50.1154413	2026-07-03 00:36:29.518757
778	7	177	26.411917	50.1154413	2026-07-03 00:36:30.331292
779	7	177	26.4116136	50.1152336	2026-07-03 00:36:34.634988
780	7	177	26.4116136	50.1152336	2026-07-03 00:36:35.311819
783	7	177	26.4113505	50.1150577	2026-07-03 00:36:44.730062
784	7	177	26.4113505	50.1150577	2026-07-03 00:36:45.307902
785	7	177	26.4111067	50.1148889	2026-07-03 00:36:49.577832
786	7	177	26.4111067	50.1148889	2026-07-03 00:36:50.32442
787	7	177	26.4108142	50.114691	2026-07-03 00:36:54.55812
794	7	177	26.4102582	50.1143403	2026-07-03 00:37:09.949599
796	7	177	26.4099113	50.1141261	2026-07-03 00:37:14.939737
798	7	177	26.4094803	50.1138557	2026-07-03 00:37:20.36198
799	7	177	26.4092229	50.1137366	2026-07-03 00:37:24.146791
802	7	177	26.4089062	50.1134975	2026-07-03 00:37:29.977038
803	7	177	26.4084968	50.1132258	2026-07-03 00:37:34.154646
804	7	177	26.4084968	50.1132258	2026-07-03 00:37:34.903419
805	7	177	26.4081182	50.1129992	2026-07-03 00:37:39.157598
807	7	177	26.4078708	50.1128496	2026-07-03 00:37:44.293375
809	7	177	26.4077011	50.1127319	2026-07-03 00:37:49.127975
812	7	177	26.4075314	50.1125988	2026-07-03 00:37:54.88701
813	7	177	26.4074949	50.1125317	2026-07-03 00:37:59.907335
814	7	177	26.4075438	50.1124848	2026-07-03 00:38:02.175102
816	7	177	26.4078585	50.1123123	2026-07-03 00:38:07.199799
818	7	177	26.4083348	50.1120554	2026-07-03 00:38:12.258998
819	7	177	26.4085319	50.1119565	2026-07-03 00:38:14.92916
820	7	177	26.4088396	50.1118054	2026-07-03 00:38:17.192299
821	7	177	26.4090287	50.111664	2026-07-03 00:38:19.921694
824	7	177	26.4098758	50.1111874	2026-07-03 00:38:27.132247
825	7	177	26.4100653	50.1110696	2026-07-03 00:38:29.988228
826	7	177	26.4103347	50.1109266	2026-07-03 00:38:32.15761
827	7	177	26.4104812	50.1108582	2026-07-03 00:38:34.918198
828	7	177	26.4105918	50.1107452	2026-07-03 00:38:37.674947
830	7	177	26.4104199	50.1105959	2026-07-03 00:38:42.627286
833	7	177	26.4098244	50.11085	2026-07-03 00:38:50.376384
835	7	177	26.4092826	50.1111184	2026-07-03 00:38:55.3969
781	7	177	26.4114867	50.115156	2026-07-03 00:36:39.62093
782	7	177	26.4114867	50.115156	2026-07-03 00:36:40.335044
788	7	177	26.4108142	50.114691	2026-07-03 00:36:54.930563
789	7	177	26.4106241	50.1145601	2026-07-03 00:36:59.377551
790	7	177	26.4106241	50.1145601	2026-07-03 00:36:59.95888
791	7	177	26.4104572	50.1144596	2026-07-03 00:37:04.185509
792	7	177	26.4104572	50.1144596	2026-07-03 00:37:04.997383
793	7	177	26.4102582	50.1143403	2026-07-03 00:37:09.187631
795	7	177	26.4099113	50.1141261	2026-07-03 00:37:14.17603
797	7	177	26.4094803	50.1138557	2026-07-03 00:37:19.158694
800	7	177	26.4092229	50.1137366	2026-07-03 00:37:24.937475
801	7	177	26.4089062	50.1134975	2026-07-03 00:37:29.206172
806	7	177	26.4081182	50.1129992	2026-07-03 00:37:40.016679
808	7	177	26.4078708	50.1128496	2026-07-03 00:37:44.946194
810	7	177	26.4077011	50.1127319	2026-07-03 00:37:49.980056
811	7	177	26.4075314	50.1125988	2026-07-03 00:37:54.368281
815	7	177	26.4076467	50.1124204	2026-07-03 00:38:05.054109
817	7	177	26.4080314	50.1122222	2026-07-03 00:38:09.942975
822	7	177	26.4093631	50.1114678	2026-07-03 00:38:22.160375
823	7	177	26.4095815	50.1113555	2026-07-03 00:38:24.924664
829	7	177	26.410573	50.1106443	2026-07-03 00:38:40.39566
831	7	177	26.4102778	50.1106438	2026-07-03 00:38:45.334828
832	7	177	26.410015	50.1107587	2026-07-03 00:38:47.739257
834	7	177	26.409508	50.1109986	2026-07-03 00:38:52.679524
836	7	177	26.4089223	50.111309	2026-07-03 00:38:57.688003
837	7	177	26.4086723	50.1114356	2026-07-03 00:39:00.344778
838	7	177	26.408312	50.111623	2026-07-03 00:39:02.673476
839	7	177	26.4080704	50.1117435	2026-07-03 00:39:05.331638
840	7	177	26.4076872	50.1119253	2026-07-03 00:39:07.580028
841	7	177	26.4074417	50.1120433	2026-07-03 00:39:10.283233
842	7	177	26.4070699	50.1122435	2026-07-03 00:39:12.517542
843	7	177	26.4068092	50.11238	2026-07-03 00:39:15.678233
844	7	177	26.4064193	50.1125871	2026-07-03 00:39:17.549977
845	7	177	26.4061538	50.1127226	2026-07-03 00:39:20.310968
846	7	177	26.405778	50.1129257	2026-07-03 00:39:22.772816
847	7	177	26.4055387	50.1130514	2026-07-03 00:39:25.402183
848	7	177	26.4051868	50.1132416	2026-07-03 00:39:27.550666
849	7	177	26.4049561	50.1133732	2026-07-03 00:39:30.335068
850	7	177	26.4045948	50.113564	2026-07-03 00:39:32.594629
851	7	177	26.4043423	50.1136949	2026-07-03 00:39:35.29077
852	7	177	26.4039997	50.1138657	2026-07-03 00:39:37.639692
853	7	177	26.3945071	50.1179732	2026-07-03 00:40:40.012678
854	7	177	26.3939179	50.1181417	2026-07-03 00:40:42.15657
855	7	177	26.3935169	50.1182526	2026-07-03 00:40:45.03388
856	7	177	26.3929297	50.1184285	2026-07-03 00:40:47.535557
857	7	177	26.3925389	50.1185501	2026-07-03 00:40:49.937022
858	7	177	26.3919549	50.1187201	2026-07-03 00:40:52.208035
859	7	177	26.3915661	50.1188316	2026-07-03 00:40:55.043502
860	7	177	26.390987	50.1189948	2026-07-03 00:40:57.28686
861	7	177	26.3906001	50.1191117	2026-07-03 00:40:59.917678
862	7	177	26.390022	50.1192866	2026-07-03 00:41:02.319923
863	7	177	26.3896299	50.1194015	2026-07-03 00:41:04.962267
864	7	177	26.3890334	50.1195776	2026-07-03 00:41:07.222529
865	7	177	26.388629	50.1196825	2026-07-03 00:41:10.005432
866	7	177	26.3880339	50.119867	2026-07-03 00:41:12.565077
867	7	177	26.3876254	50.1199895	2026-07-03 00:41:14.907872
868	7	177	26.3870222	50.1201537	2026-07-03 00:41:17.247731
869	7	177	26.3866251	50.1202661	2026-07-03 00:41:19.940328
870	7	177	26.3860291	50.1204382	2026-07-03 00:41:22.473758
871	7	177	26.3856384	50.1205511	2026-07-03 00:41:24.932456
872	7	177	26.3850559	50.1207057	2026-07-03 00:41:27.363994
873	7	177	26.3846815	50.120802	2026-07-03 00:41:29.926809
874	7	177	26.3841277	50.1209304	2026-07-03 00:41:32.151598
875	7	177	26.3837761	50.1210127	2026-07-03 00:41:34.929859
876	7	177	26.3832648	50.1211408	2026-07-03 00:41:37.33399
877	7	177	26.3829389	50.1212257	2026-07-03 00:41:40.408656
878	7	177	26.3824439	50.1213676	2026-07-03 00:41:42.564643
879	7	177	26.3821217	50.1214645	2026-07-03 00:41:45.347315
880	7	177	26.3816518	50.1216036	2026-07-03 00:41:47.541185
881	7	177	26.3813503	50.1216929	2026-07-03 00:41:50.311316
882	7	177	26.3809216	50.1218226	2026-07-03 00:41:52.478672
883	7	177	26.3806521	50.1219039	2026-07-03 00:41:55.420606
884	7	177	26.3802517	50.1220095	2026-07-03 00:41:57.551827
885	7	177	26.3800094	50.1220356	2026-07-03 00:42:00.33121
886	7	177	26.3796735	50.1221343	2026-07-03 00:42:02.511535
887	7	177	26.3794832	50.1221809	2026-07-03 00:42:05.346472
888	7	177	26.3792335	50.122247	2026-07-03 00:42:07.535647
889	7	177	26.3790725	50.1222881	2026-07-03 00:42:10.331412
890	7	177	26.378864	50.1223595	2026-07-03 00:42:12.249468
891	7	177	26.3787625	50.122397	2026-07-03 00:42:15.480483
892	7	177	26.3786584	50.1223871	2026-07-03 00:42:17.724626
893	7	177	26.3786149	50.1223158	2026-07-03 00:42:20.327227
894	7	177	26.3785918	50.1221213	2026-07-03 00:42:22.593018
895	7	177	26.3785601	50.1220027	2026-07-03 00:42:25.342242
896	7	177	26.3785237	50.1218275	2026-07-03 00:42:27.626925
897	7	177	26.37849	50.1217142	2026-07-03 00:42:30.358989
898	7	177	26.3784544	50.1216189	2026-07-03 00:42:32.64427
899	7	177	26.3783544	50.1213504	2026-07-03 00:43:35.338257
900	7	177	26.3783482	50.1213402	2026-07-03 00:43:40.365024
901	7	177	26.3783405	50.1213409	2026-07-03 00:43:45.412743
902	7	177	26.3783404	50.121341	2026-07-03 00:43:50.406858
903	7	177	26.3783404	50.121341	2026-07-03 00:43:55.314908
904	7	177	26.3783404	50.121341	2026-07-03 00:44:00.346685
905	7	177	26.3783417	50.1213355	2026-07-03 00:44:05.300758
906	7	178	26.3795199	50.1171561	2026-07-03 18:11:59.803711
907	7	178	26.3795098	50.1169956	2026-07-03 18:12:04.878453
908	7	178	26.3795045	50.1169165	2026-07-03 18:12:11.127059
909	7	178	26.3794774	50.1168477	2026-07-03 18:12:15.15298
910	7	178	26.3794625	50.1168389	2026-07-03 18:12:16.133681
911	7	178	26.3793856	50.1169018	2026-07-03 18:12:19.992138
912	7	178	26.3793846	50.1169427	2026-07-03 18:12:21.054425
913	7	178	26.3794278	50.1171567	2026-07-03 18:12:24.999881
914	7	178	26.3794427	50.117221	2026-07-03 18:12:26.258145
915	7	178	26.379512	50.1175316	2026-07-03 18:12:29.986937
916	7	178	26.3795295	50.1176271	2026-07-03 18:12:31.296385
917	7	178	26.3796004	50.1180182	2026-07-03 18:12:35.079565
918	7	178	26.3796176	50.1181144	2026-07-03 18:12:36.305941
919	7	178	26.3796855	50.1185082	2026-07-03 18:12:40.034089
920	7	178	26.3797035	50.1185942	2026-07-03 18:12:41.298649
921	7	178	26.3797474	50.1188532	2026-07-03 18:12:45.069767
922	7	178	26.3797568	50.1188952	2026-07-03 18:12:46.264971
923	7	178	26.3797891	50.1191096	2026-07-03 18:12:49.957873
924	7	178	26.3798	50.1191912	2026-07-03 18:12:51.275109
925	7	178	26.3798507	50.1195508	2026-07-03 18:12:54.966318
927	7	178	26.3799219	50.1199874	2026-07-03 18:13:00.052941
929	7	178	26.3799628	50.1203164	2026-07-03 18:13:05.023876
933	7	178	26.3800635	50.1210968	2026-07-03 18:13:15.087405
935	7	178	26.3798096	50.1211971	2026-07-03 18:13:20.368086
936	7	178	26.3797494	50.1212133	2026-07-03 18:13:21.728086
937	7	178	26.3794843	50.1212943	2026-07-03 18:13:25.433973
938	7	178	26.3794123	50.1213125	2026-07-03 18:13:26.386651
939	7	178	26.3791463	50.1213789	2026-07-03 18:13:30.237609
940	7	178	26.3790788	50.1213813	2026-07-03 18:13:31.268243
941	7	179	26.3785209	50.1215491	2026-07-03 18:18:28.756793
942	7	179	26.3785203	50.1215517	2026-07-03 18:18:33.701666
943	7	179	26.3785209	50.1215477	2026-07-03 18:18:38.768144
945	7	179	26.3784865	50.1216504	2026-07-03 18:18:48.924638
946	7	179	26.3785271	50.1217458	2026-07-03 18:18:49.175731
948	7	179	26.3785871	50.1221155	2026-07-03 18:18:54.064936
950	7	179	26.378649	50.1223959	2026-07-03 18:18:59.161551
951	7	179	26.3786263	50.1224678	2026-07-03 18:19:03.823914
952	7	179	26.3785797	50.122473	2026-07-03 18:19:05.093584
953	7	179	26.3784902	50.1224663	2026-07-03 18:19:08.792629
955	7	179	26.378358	50.1224694	2026-07-03 18:19:14.258195
956	7	179	26.3782923	50.1225002	2026-07-03 18:19:15.121506
958	7	179	26.3779486	50.1226212	2026-07-03 18:19:20.068944
959	7	179	26.3776396	50.1227235	2026-07-03 18:19:23.779115
960	7	179	26.3774189	50.1228025	2026-07-03 18:19:25.081403
961	7	179	26.3770592	50.1229306	2026-07-03 18:19:28.745994
963	7	179	26.3764002	50.123154	2026-07-03 18:19:34.736224
965	7	179	26.3756405	50.1233655	2026-07-03 18:19:39.034079
967	7	179	26.3748861	50.123602	2026-07-03 18:19:43.552222
968	7	179	26.3746017	50.1236831	2026-07-03 18:19:44.812315
969	7	179	26.3741998	50.1237952	2026-07-03 18:19:48.63216
971	7	179	26.3736686	50.1239015	2026-07-03 18:19:53.613353
972	7	179	26.3735598	50.123826	2026-07-03 18:19:54.845852
973	7	179	26.3735371	50.1235954	2026-07-03 18:20:00.337286
974	7	179	26.3735689	50.1234039	2026-07-03 18:20:00.530958
976	7	179	26.3736523	50.1227985	2026-07-03 18:20:04.888859
978	7	179	26.3737516	50.1221058	2026-07-03 18:20:09.814985
979	7	179	26.3738257	50.1216648	2026-07-03 18:20:13.562561
981	7	179	26.3739147	50.1209946	2026-07-03 18:20:18.600727
982	7	179	26.3739549	50.1207636	2026-07-03 18:20:19.815866
983	7	179	26.3739912	50.1205387	2026-07-03 18:20:23.574722
985	7	179	26.3738323	50.1205948	2026-07-03 18:20:28.616794
987	7	179	26.3737379	50.1210207	2026-07-03 18:20:33.623133
988	7	179	26.3736992	50.1212424	2026-07-03 18:20:35.003414
989	7	179	26.3736339	50.1216095	2026-07-03 18:20:38.594846
990	7	179	26.3735785	50.1218892	2026-07-03 18:20:40.027912
992	7	179	26.3734423	50.1226578	2026-07-03 18:20:45.053115
993	7	179	26.3733583	50.1230907	2026-07-03 18:20:48.806447
994	7	179	26.3733046	50.1233583	2026-07-03 18:20:50.079401
995	7	179	26.3732464	50.1237303	2026-07-03 18:20:53.805589
996	7	179	26.3732004	50.1239443	2026-07-03 18:20:55.059623
1000	7	179	26.3722002	50.1244121	2026-07-03 18:21:04.963175
1001	7	179	26.3717923	50.1245403	2026-07-03 18:21:08.789088
1002	7	179	26.3714959	50.1246253	2026-07-03 18:21:10.356456
1003	7	179	26.3710227	50.1247663	2026-07-03 18:21:13.72147
1005	7	179	26.3701741	50.1250264	2026-07-03 18:21:18.899065
1006	7	179	26.3698158	50.1251335	2026-07-03 18:21:20.038541
1007	7	179	26.3692702	50.1252825	2026-07-03 18:21:23.752111
1009	7	179	26.3683553	50.1255556	2026-07-03 18:21:28.817232
1010	7	179	26.3679919	50.1256743	2026-07-03 18:21:30.018745
1012	7	179	26.3670758	50.1259464	2026-07-03 18:21:34.984233
1019	7	179	26.3636104	50.1273096	2026-07-03 18:21:53.727153
1021	7	179	26.3627091	50.1278068	2026-07-03 18:21:58.733803
1025	7	179	26.3609988	50.1289193	2026-07-03 18:22:08.797943
1027	7	179	26.3602176	50.129543	2026-07-03 18:22:13.760523
1028	7	179	26.3599255	50.1298005	2026-07-03 18:22:15.8593
1030	7	179	26.3592461	50.1304217	2026-07-03 18:22:20.021643
1031	7	179	26.3588512	50.13082	2026-07-03 18:22:23.835006
1033	7	179	26.3582054	50.1314907	2026-07-03 18:22:28.7132
1035	7	179	26.3575766	50.1321344	2026-07-03 18:22:33.731366
1036	7	179	26.3573389	50.1323761	2026-07-03 18:22:35.005563
1039	7	179	26.3564207	50.1332799	2026-07-03 18:22:43.512006
926	7	178	26.3798623	50.1196412	2026-07-03 18:12:56.287447
928	7	178	26.3799344	50.1200769	2026-07-03 18:13:01.273065
930	7	178	26.3799731	50.1203781	2026-07-03 18:13:06.326946
931	7	178	26.3800276	50.1207078	2026-07-03 18:13:10.081094
932	7	178	26.3800428	50.1207999	2026-07-03 18:13:11.341906
934	7	178	26.3800373	50.1211481	2026-07-03 18:13:16.268719
944	7	179	26.3785202	50.1215464	2026-07-03 18:18:43.677518
947	7	179	26.3785775	50.1220356	2026-07-03 18:18:53.872111
949	7	179	26.3786391	50.1223647	2026-07-03 18:18:58.811356
954	7	179	26.3784288	50.1224612	2026-07-03 18:19:09.985961
957	7	179	26.3781048	50.1225535	2026-07-03 18:19:18.82425
962	7	179	26.3768106	50.1230158	2026-07-03 18:19:30.027387
964	7	179	26.376104	50.1232367	2026-07-03 18:19:34.995787
966	7	179	26.3753377	50.1234603	2026-07-03 18:19:39.835699
970	7	179	26.3739471	50.1238613	2026-07-03 18:19:49.83553
975	7	179	26.3736146	50.1230502	2026-07-03 18:20:03.582085
977	7	179	26.3737156	50.1224013	2026-07-03 18:20:08.585261
980	7	179	26.373861	50.1213827	2026-07-03 18:20:14.800175
984	7	179	26.3739434	50.1204709	2026-07-03 18:20:24.852053
986	7	179	26.3737953	50.1207492	2026-07-03 18:20:29.966734
991	7	179	26.3734926	50.1223532	2026-07-03 18:20:43.765195
997	7	179	26.3729799	50.1241411	2026-07-03 18:20:58.815646
998	7	179	26.3727869	50.1242235	2026-07-03 18:21:00.113203
999	7	179	26.3724522	50.1243362	2026-07-03 18:21:03.694555
1004	7	179	26.3706966	50.1248721	2026-07-03 18:21:15.223573
1008	7	179	26.3688998	50.1253929	2026-07-03 18:21:25.007883
1011	7	179	26.3674449	50.1258424	2026-07-03 18:21:33.730413
1013	7	179	26.3665022	50.1261157	2026-07-03 18:21:38.783409
1014	7	179	26.3661204	50.1262421	2026-07-03 18:21:39.851024
1015	7	179	26.3655449	50.1264597	2026-07-03 18:21:43.731431
1016	7	179	26.3651608	50.1266152	2026-07-03 18:21:45.050185
1017	7	179	26.3645728	50.1268536	2026-07-03 18:21:48.89431
1018	7	179	26.3641834	50.1270275	2026-07-03 18:21:49.972287
1020	7	179	26.3632375	50.1275074	2026-07-03 18:21:55.065896
1022	7	179	26.3623611	50.1280116	2026-07-03 18:22:00.018418
1023	7	179	26.3618344	50.1283313	2026-07-03 18:22:03.723821
1024	7	179	26.3614948	50.1285582	2026-07-03 18:22:04.990991
1026	7	179	26.3606784	50.1291611	2026-07-03 18:22:10.007631
1029	7	179	26.3595174	50.1301694	2026-07-03 18:22:18.86296
1032	7	179	26.3585927	50.1310921	2026-07-03 18:22:25.015037
1034	7	179	26.3579446	50.1317554	2026-07-03 18:22:30.007906
1037	7	179	26.3569918	50.1327215	2026-07-03 18:22:38.732024
1038	7	179	26.3567605	50.132955	2026-07-03 18:22:39.931537
1040	7	179	26.356182	50.1334654	2026-07-03 18:22:44.782412
1041	7	179	26.3557792	50.1336616	2026-07-03 18:22:48.521368
1042	7	179	26.355492	50.1337364	2026-07-03 18:22:49.819787
1043	7	179	26.3550441	50.1337517	2026-07-03 18:22:53.532107
1044	7	179	26.3547426	50.1337358	2026-07-03 18:22:54.757808
1045	7	179	26.3542886	50.133709	2026-07-03 18:22:58.530865
1046	7	179	26.3539896	50.1337005	2026-07-03 18:22:59.807397
1047	7	179	26.3535483	50.1336891	2026-07-03 18:23:03.474357
1048	7	179	26.3532668	50.1336774	2026-07-03 18:23:05.277211
1049	7	179	26.352847	50.1336569	2026-07-03 18:23:08.487688
1050	7	179	26.3525673	50.1336211	2026-07-03 18:23:10.071242
1051	7	179	26.3521748	50.1335007	2026-07-03 18:23:13.494029
1052	7	179	26.3519365	50.1333717	2026-07-03 18:23:14.740644
1053	7	179	26.3516199	50.1331054	2026-07-03 18:23:18.599912
1054	7	179	26.3514439	50.1328968	2026-07-03 18:23:19.776476
1055	7	179	26.3512081	50.1325363	2026-07-03 18:23:23.514027
1056	7	179	26.351079	50.1322628	2026-07-03 18:23:24.80821
1057	7	179	26.3508767	50.1318397	2026-07-03 18:23:28.516346
1058	7	179	26.3507492	50.1315543	2026-07-03 18:23:29.87314
1059	7	179	26.3505607	50.131114	2026-07-03 18:23:33.543194
1060	7	179	26.3504332	50.1308152	2026-07-03 18:23:34.820732
1061	7	179	26.3502548	50.130352	2026-07-03 18:23:38.518573
1062	7	179	26.3501406	50.130032	2026-07-03 18:23:39.839394
1063	7	179	26.3499805	50.1295382	2026-07-03 18:23:43.696335
1064	7	179	26.34987	50.1292067	2026-07-03 18:23:44.80823
1065	7	179	26.3497238	50.1287238	2026-07-03 18:23:48.507929
1066	7	179	26.3496331	50.1284182	2026-07-03 18:23:49.805732
1067	7	179	26.3495103	50.1279989	2026-07-03 18:23:53.539449
1068	7	179	26.3494392	50.1277585	2026-07-03 18:23:54.841463
1069	7	179	26.3493682	50.1275005	2026-07-03 18:23:58.617214
1070	7	179	26.3493377	50.1274066	2026-07-03 18:23:59.854475
1071	7	179	26.3493024	50.1273101	2026-07-03 18:24:03.615186
1072	7	179	26.3492723	50.1272278	2026-07-03 18:24:04.942859
1073	7	179	26.3492057	50.1270771	2026-07-03 18:24:08.555829
1074	7	179	26.3491131	50.1270166	2026-07-03 18:24:09.773838
1075	7	179	26.3489193	50.1269902	2026-07-03 18:24:13.505257
1076	7	179	26.3487726	50.1269883	2026-07-03 18:24:14.873337
1077	7	179	26.3485518	50.1269662	2026-07-03 18:24:18.47233
1078	7	179	26.3484513	50.1269874	2026-07-03 18:24:19.805028
1079	7	179	26.3484277	50.1271766	2026-07-03 18:24:23.525162
1080	7	179	26.3484964	50.1273412	2026-07-03 18:24:24.734656
1081	7	179	26.3486014	50.1276427	2026-07-03 18:24:28.780035
1082	7	179	26.3486654	50.1278858	2026-07-03 18:24:29.790483
1083	7	179	26.3487791	50.1282923	2026-07-03 18:24:33.549486
1084	7	179	26.3488678	50.1285837	2026-07-03 18:24:34.773855
1085	7	179	26.3490268	50.1290347	2026-07-03 18:24:38.563086
1086	7	179	26.3491361	50.1293531	2026-07-03 18:24:39.844597
1087	7	179	26.3509219	50.1355805	2026-07-03 18:25:18.566352
1088	7	179	26.3508308	50.1374995	2026-07-03 18:25:28.736411
1089	7	179	26.350821	50.1378688	2026-07-03 18:25:30.265606
1090	7	179	26.3507881	50.1383321	2026-07-03 18:25:33.709638
1091	7	179	26.3507508	50.1385494	2026-07-03 18:25:34.99052
1092	7	179	26.3506476	50.1388669	2026-07-03 18:25:38.713696
1093	7	179	26.3505313	50.1390814	2026-07-03 18:25:39.832799
1094	7	179	26.3502772	50.1393911	2026-07-03 18:25:44.080472
1095	7	179	26.3500833	50.139601	2026-07-03 18:25:44.815062
1096	7	179	26.3498316	50.139875	2026-07-03 18:25:48.574183
1097	7	179	26.3496694	50.1400596	2026-07-03 18:25:50.07821
1098	7	179	26.3494082	50.1403227	2026-07-03 18:25:53.73998
1099	7	179	26.3492341	50.1405003	2026-07-03 18:25:54.789876
1100	7	179	26.3489766	50.1407534	2026-07-03 18:25:59.385235
1101	7	179	26.3488159	50.1409177	2026-07-03 18:25:59.95488
1102	7	179	26.3485839	50.1411665	2026-07-03 18:26:03.633768
1103	7	179	26.3484361	50.1413184	2026-07-03 18:26:04.794228
1104	7	179	26.3482562	50.1415172	2026-07-03 18:26:08.525108
1105	7	179	26.3481854	50.1415887	2026-07-03 18:26:09.770826
1106	7	179	26.3481441	50.141643	2026-07-03 18:26:13.628192
1107	7	179	26.3481416	50.1416457	2026-07-03 18:26:18.583463
1108	7	179	26.3481416	50.1416457	2026-07-03 18:26:23.503108
1109	7	179	26.3481416	50.1416457	2026-07-03 18:26:28.538734
1110	7	179	26.3481416	50.1416457	2026-07-03 18:26:33.546567
1111	7	179	26.3481416	50.1416457	2026-07-03 18:26:38.515343
1112	7	179	26.3481416	50.1416457	2026-07-03 18:26:43.766701
1113	7	179	26.3481416	50.1416457	2026-07-03 18:26:48.549283
1114	7	179	26.3481416	50.1416457	2026-07-03 18:26:53.678939
1115	7	179	26.3481416	50.1416457	2026-07-03 18:26:58.550318
1116	7	179	26.3481416	50.1416457	2026-07-03 18:27:03.548365
1117	7	179	26.3481416	50.1416457	2026-07-03 18:27:08.57871
1118	7	179	26.3481331	50.1416467	2026-07-03 18:27:13.620855
1119	7	179	26.3479858	50.1418101	2026-07-03 18:27:16.985236
1120	7	179	26.3479858	50.1418101	2026-07-03 18:27:18.666475
1121	7	179	26.3480251	50.1421476	2026-07-03 18:27:21.863858
1122	7	179	26.3480251	50.1421476	2026-07-03 18:27:23.463177
1123	7	179	26.3482754	50.1424924	2026-07-03 18:27:26.847668
1124	7	179	26.3482754	50.1424924	2026-07-03 18:27:28.769965
1125	7	179	26.3484488	50.1427044	2026-07-03 18:27:31.880285
1126	7	179	26.3484488	50.1427044	2026-07-03 18:27:33.595103
1127	7	179	26.3485364	50.1428739	2026-07-03 18:27:36.852384
1128	7	179	26.3485364	50.1428739	2026-07-03 18:27:38.569637
1129	7	179	26.3484589	50.1429744	2026-07-03 18:27:43.570453
1130	7	180	26.3501008	50.1493479	2026-07-03 19:06:04.766189
1131	7	180	26.3501019	50.1493469	2026-07-03 19:06:04.935133
1132	7	180	26.3501288	50.1493137	2026-07-03 19:06:09.890802
1133	7	180	26.3501525	50.1492645	2026-07-03 19:06:14.699688
1134	7	180	26.3501528	50.1492638	2026-07-03 19:06:14.936762
1135	7	180	26.3501775	50.1492146	2026-07-03 19:06:19.955764
1136	7	180	26.3502031	50.1491806	2026-07-03 19:06:23.709561
1137	7	180	26.3502099	50.1491694	2026-07-03 19:06:24.926423
1138	7	180	26.3502331	50.149114	2026-07-03 19:06:29.927427
1139	7	180	26.3502446	50.1490908	2026-07-03 19:06:32.568369
1140	7	180	26.3502611	50.1490822	2026-07-03 19:06:35.047671
1141	7	180	26.3503071	50.1490596	2026-07-03 19:06:40.128022
1142	7	180	26.3503286	50.1490483	2026-07-03 19:06:41.855118
1143	7	180	26.3503597	50.1490269	2026-07-03 19:06:44.989424
1144	7	180	26.3504069	50.1490002	2026-07-03 19:06:49.99831
1145	7	180	26.3504112	50.1489991	2026-07-03 19:06:50.142217
1146	7	180	26.3504625	50.1489859	2026-07-03 19:06:55.005096
1147	7	180	26.3505005	50.1489716	2026-07-03 19:06:58.206558
1148	7	180	26.3505192	50.1489605	2026-07-03 19:06:59.960549
1149	7	180	26.3505632	50.1489248	2026-07-03 19:07:05.023687
1150	7	180	26.3505756	50.1489118	2026-07-03 19:07:06.432252
1151	7	180	26.3506075	50.1488875	2026-07-03 19:07:09.868228
1152	7	180	26.3506436	50.1488557	2026-07-03 19:07:15.080888
1153	7	180	26.35065	50.1488506	2026-07-03 19:07:15.455914
1154	7	180	26.3506924	50.1488247	2026-07-03 19:07:19.959747
1155	7	180	26.3507332	50.1488082	2026-07-03 19:07:23.059381
1156	7	180	26.3507576	50.1487951	2026-07-03 19:07:24.910418
1157	7	180	26.3508047	50.1487731	2026-07-03 19:07:29.957855
1158	7	180	26.3508185	50.1487657	2026-07-03 19:07:31.037342
1159	7	180	26.3508518	50.1487392	2026-07-03 19:07:35.010659
1160	7	180	26.3508921	50.1487075	2026-07-03 19:07:38.60892
1161	7	180	26.3509009	50.1487023	2026-07-03 19:07:39.957732
1162	7	180	26.3509498	50.1486719	2026-07-03 19:07:44.958034
1163	7	180	26.3509738	50.1486594	2026-07-03 19:07:47.101755
1164	7	180	26.351005	50.1486454	2026-07-03 19:07:49.920679
1165	7	180	26.3510456	50.1486124	2026-07-03 19:07:54.933816
1166	7	180	26.3510537	50.1486063	2026-07-03 19:07:55.660782
1167	7	180	26.3510919	50.1485775	2026-07-03 19:08:00.05849
1168	7	180	26.3511343	50.1485546	2026-07-03 19:08:04.965923
1169	7	180	26.3511354	50.1485544	2026-07-03 19:08:05.015529
1170	7	180	26.3514024	50.1483763	2026-07-03 19:08:35.155013
1171	7	180	26.3513918	50.148308	2026-07-03 19:08:39.785065
1172	7	180	26.3513894	50.1482999	2026-07-03 19:08:40.357336
1173	7	180	26.3513943	50.1482289	2026-07-03 19:08:45.243175
1174	7	180	26.3514371	50.1482147	2026-07-03 19:08:47.995485
1175	7	180	26.3514594	50.148205	2026-07-03 19:08:50.115755
1176	7	180	26.3514981	50.1481717	2026-07-03 19:08:55.17594
1177	7	180	26.351503	50.1481656	2026-07-03 19:09:00.155102
1178	7	180	26.3515012	50.1481722	2026-07-03 19:09:05.279595
1179	7	180	26.351501	50.1481791	2026-07-03 19:09:10.136177
1180	7	180	26.3515007	50.1481806	2026-07-03 19:09:15.081993
1181	7	181	26.3793712	50.120728	2026-07-03 19:35:28.852915
1182	7	181	26.3793896	50.1209059	2026-07-03 19:35:33.797093
1183	7	181	26.3794133	50.1210877	2026-07-03 19:35:38.86655
1184	7	181	26.3793961	50.1212728	2026-07-03 19:35:44.162454
1185	7	181	26.3793961	50.1212728	2026-07-03 19:35:46.785248
1186	7	181	26.3792581	50.1213205	2026-07-03 19:35:48.890154
1187	7	181	26.3792288	50.1213233	2026-07-03 19:35:51.82771
1188	7	181	26.3791131	50.1213417	2026-07-03 19:35:53.986029
1189	7	181	26.3790524	50.1213658	2026-07-03 19:35:56.952515
1190	7	181	26.3789841	50.1213881	2026-07-03 19:36:01.778021
1191	7	181	26.378836	50.1214293	2026-07-03 19:36:02.959872
1192	7	181	26.378836	50.1214293	2026-07-03 19:36:06.775673
1193	7	181	26.3787018	50.1214346	2026-07-03 19:36:07.911182
1194	7	181	26.3787018	50.1214346	2026-07-03 19:36:11.785369
1195	7	181	26.3786415	50.1214497	2026-07-03 19:36:16.828326
1196	7	181	26.3785845	50.1214782	2026-07-03 19:36:17.996422
1197	7	181	26.3785845	50.1214782	2026-07-03 19:36:21.841072
1198	7	181	26.3784947	50.1215198	2026-07-03 19:39:32.808418
1199	7	181	26.3782955	50.1215934	2026-07-03 19:39:42.729037
1200	7	181	26.3781178	50.1216514	2026-07-03 19:39:47.739576
1201	7	181	26.3779144	50.1217377	2026-07-03 19:39:52.989189
1202	7	181	26.3777134	50.1218028	2026-07-03 19:39:57.82271
1203	7	181	26.3775261	50.1218899	2026-07-03 19:40:02.832091
1204	7	181	26.3772868	50.1219094	2026-07-03 19:40:07.79343
1205	7	181	26.3772868	50.1219094	2026-07-03 19:40:11.459398
1206	7	181	26.3770658	50.1219777	2026-07-03 19:40:12.938438
1207	7	181	26.3769489	50.1220226	2026-07-03 19:40:16.338956
1208	7	181	26.3768555	50.1220576	2026-07-03 19:40:17.986783
1209	7	181	26.3767297	50.1220845	2026-07-03 19:40:21.326477
1210	7	181	26.3766593	50.1220985	2026-07-03 19:40:22.998581
1211	7	181	26.3765794	50.1220713	2026-07-03 19:40:26.349838
1212	7	181	26.3765609	50.1220114	2026-07-03 19:40:28.030016
1213	7	181	26.3765684	50.1218745	2026-07-03 19:40:31.319517
1214	7	181	26.376611	50.1217371	2026-07-03 19:40:33.044564
1215	7	181	26.3766433	50.1215184	2026-07-03 19:40:36.508757
1216	7	181	26.3766709	50.1213609	2026-07-03 19:40:38.126469
1217	7	181	26.3767156	50.1211262	2026-07-03 19:40:41.37051
1218	7	181	26.3767353	50.1209703	2026-07-03 19:40:42.999823
1219	7	181	26.3767807	50.1207183	2026-07-03 19:40:46.326486
1220	7	181	26.3768075	50.1205422	2026-07-03 19:40:47.950382
1221	7	181	26.3768504	50.1203003	2026-07-03 19:40:51.305885
1222	7	181	26.3768778	50.1201423	2026-07-03 19:40:53.033234
1223	7	181	26.3769173	50.1198846	2026-07-03 19:40:56.26897
1224	7	181	26.3769479	50.1197098	2026-07-03 19:40:58.052517
1225	7	181	26.3770009	50.1194588	2026-07-03 19:41:01.294385
1226	7	181	26.377017	50.1192995	2026-07-03 19:41:03.034991
1227	7	181	26.3771046	50.1191076	2026-07-03 19:41:16.093372
1228	7	181	26.3771046	50.1191076	2026-07-03 19:41:21.131938
1229	7	181	26.3771046	50.1191076	2026-07-03 19:41:26.071878
1230	7	181	26.3771046	50.1191076	2026-07-03 19:41:31.081873
1231	7	181	26.3771046	50.1191076	2026-07-03 19:41:36.146681
1232	7	181	26.3770977	50.119141	2026-07-03 19:41:41.05084
1233	7	181	26.3770916	50.1191688	2026-07-03 19:41:46.137111
1234	7	181	26.3770892	50.1191752	2026-07-03 19:41:51.140628
1235	7	181	26.3770666	50.1192407	2026-07-03 19:41:56.06686
1236	7	181	26.3770495	50.1193473	2026-07-03 19:42:01.185545
1240	7	181	26.3772057	50.1194619	2026-07-03 19:42:21.327397
1262	7	182	26.3795578	50.1179526	2026-07-03 19:46:08.84022
1237	7	181	26.3770385	50.1194288	2026-07-03 19:42:06.092784
1238	7	181	26.3770269	50.1194833	2026-07-03 19:42:11.496748
1239	7	181	26.3770417	50.1194893	2026-07-03 19:42:16.281013
1241	7	181	26.3774324	50.1194312	2026-07-03 19:42:26.356146
1242	7	181	26.377682	50.1194081	2026-07-03 19:42:31.275413
1243	7	181	26.3779629	50.119371	2026-07-03 19:42:36.263102
1244	7	181	26.3781614	50.1193401	2026-07-03 19:42:41.307728
1245	7	181	26.3783763	50.1192961	2026-07-03 19:42:46.349208
1246	7	181	26.3786202	50.1192467	2026-07-03 19:42:51.287729
1247	7	181	26.3787782	50.1192236	2026-07-03 19:42:56.289849
1248	7	181	26.3788241	50.1192106	2026-07-03 19:43:01.267633
1249	7	181	26.3788241	50.1192105	2026-07-03 19:43:06.335573
1250	7	181	26.3788241	50.1192105	2026-07-03 19:43:11.423574
1251	7	181	26.3788241	50.1192105	2026-07-03 19:43:16.255463
1252	7	181	26.3788241	50.1192105	2026-07-03 19:43:21.277245
1253	7	181	26.3788241	50.1192105	2026-07-03 19:43:26.465613
1254	7	182	26.3797398	50.1185175	2026-07-03 19:45:28.777342
1255	7	182	26.3796884	50.1184066	2026-07-03 19:45:33.757966
1256	7	182	26.3796584	50.1181451	2026-07-03 19:45:38.797426
1257	7	182	26.3796223	50.1178212	2026-07-03 19:45:44.275988
1258	7	182	26.3795771	50.1175198	2026-07-03 19:45:48.789122
1259	7	182	26.3795462	50.1173131	2026-07-03 19:45:53.751104
1260	7	182	26.3794383	50.1173407	2026-07-03 19:45:58.786938
1261	7	182	26.3794972	50.1176126	2026-07-03 19:46:03.825587
1263	7	182	26.379577	50.1182631	2026-07-03 19:46:14.135657
1264	7	182	26.3796088	50.1185223	2026-07-03 19:46:18.981009
1265	7	182	26.3796275	50.1186248	2026-07-03 19:46:23.981027
1266	7	183	26.379403	50.1208689	2026-07-03 21:19:08.38147
1267	7	183	26.379399	50.1208762	2026-07-03 21:19:13.149037
1268	7	183	26.3794098	50.1209387	2026-07-03 21:19:15.428155
1269	7	183	26.3794364	50.121022	2026-07-03 21:19:18.218048
1270	7	183	26.3794464	50.121196	2026-07-03 21:19:20.355582
1271	7	183	26.3794026	50.1212842	2026-07-03 21:19:23.107465
1272	7	183	26.3793022	50.1213352	2026-07-03 21:19:25.210879
1273	7	183	26.3792257	50.1213532	2026-07-03 21:19:28.084366
1274	7	183	26.3791059	50.1213786	2026-07-03 21:19:30.209217
1275	7	183	26.3790242	50.1213899	2026-07-03 21:19:33.059281
1276	7	183	26.3789114	50.1214225	2026-07-03 21:19:35.226464
1277	7	183	26.3788401	50.1214385	2026-07-03 21:19:38.068554
1278	7	183	26.3787605	50.1214455	2026-07-03 21:19:40.196509
1279	7	183	26.3787605	50.1214455	2026-07-03 21:19:43.089653
1280	7	183	26.3786412	50.1214609	2026-07-03 21:19:45.239363
1281	7	183	26.3785363	50.1214857	2026-07-03 21:19:50.515622
1282	7	183	26.378504	50.1215249	2026-07-03 21:21:52.482345
1283	7	183	26.378504	50.1215249	2026-07-03 21:21:57.089677
1284	7	183	26.3784907	50.1215536	2026-07-03 21:22:02.152839
1285	7	183	26.3784926	50.1215818	2026-07-03 21:22:02.235816
1286	7	183	26.3785406	50.1217664	2026-07-03 21:22:07.231227
1287	7	183	26.3785557	50.1218433	2026-07-03 21:22:07.518366
1288	7	183	26.3786164	50.1221333	2026-07-03 21:22:12.208036
1289	7	183	26.3786376	50.1222009	2026-07-03 21:22:12.374249
1290	7	183	26.3786921	50.1223814	2026-07-03 21:22:17.255949
1291	7	183	26.3786945	50.122398	2026-07-03 21:22:17.566251
1292	7	183	26.3786558	50.1224498	2026-07-03 21:22:22.107667
1293	7	183	26.3786184	50.1224582	2026-07-03 21:22:22.278112
1294	7	183	26.3784635	50.122469	2026-07-03 21:22:27.262564
1295	7	183	26.3784879	50.1224716	2026-07-03 21:22:27.339304
1296	7	183	26.3784005	50.1224783	2026-07-03 21:22:32.656937
1297	7	183	26.378366	50.1224938	2026-07-03 21:22:33.457165
1298	7	183	26.3783208	50.12254	2026-07-03 21:22:37.186688
1299	7	183	26.3782108	50.1225601	2026-07-03 21:22:38.282759
1300	7	183	26.3779929	50.1226391	2026-07-03 21:22:42.166184
1301	7	183	26.3777946	50.1227097	2026-07-03 21:22:43.218177
1302	7	183	26.3774666	50.1228196	2026-07-03 21:22:47.169832
1303	7	183	26.3772374	50.1228947	2026-07-03 21:22:48.277983
1304	7	183	26.3768657	50.122996	2026-07-03 21:22:52.181984
1305	7	183	26.376609	50.1230755	2026-07-03 21:22:53.41595
1306	7	183	26.3762114	50.1232077	2026-07-03 21:22:57.232348
1307	7	183	26.3759363	50.1232998	2026-07-03 21:22:58.431368
1308	7	183	26.3755091	50.1234471	2026-07-03 21:23:02.31643
1309	7	183	26.3752071	50.1235463	2026-07-03 21:23:03.37794
1310	7	183	26.3747662	50.1236891	2026-07-03 21:23:07.32223
1311	7	183	26.3744737	50.1237759	2026-07-03 21:23:08.391916
1312	7	183	26.3740747	50.1238974	2026-07-03 21:23:12.3087
1313	7	183	26.3738345	50.123962	2026-07-03 21:23:13.456618
1314	7	183	26.3735814	50.1240681	2026-07-03 21:23:17.617538
1315	7	183	26.3734653	50.1241778	2026-07-03 21:23:18.404868
1316	7	183	26.3733642	50.1243808	2026-07-03 21:23:22.249769
1317	7	183	26.3734634	50.1244512	2026-07-03 21:23:23.392756
1318	7	183	26.3738145	50.124417	2026-07-03 21:23:27.284966
1319	7	183	26.374015	50.1243701	2026-07-03 21:23:28.43046
1320	7	183	26.374351	50.1242647	2026-07-03 21:23:32.334309
1321	7	183	26.3745991	50.1241955	2026-07-03 21:23:33.463767
1322	7	183	26.3750183	50.1240792	2026-07-03 21:23:37.324535
1323	7	183	26.3753144	50.1239898	2026-07-03 21:23:38.378958
1324	7	183	26.375799	50.1238443	2026-07-03 21:23:42.256604
1325	7	183	26.376139	50.1237379	2026-07-03 21:23:43.399553
1326	7	183	26.3766778	50.1235805	2026-07-03 21:23:47.916803
1327	7	183	26.3770571	50.1234714	2026-07-03 21:23:48.394115
1328	7	183	26.3776451	50.1233029	2026-07-03 21:23:52.287869
1329	7	183	26.3780457	50.123184	2026-07-03 21:23:53.526961
1330	7	183	26.3786365	50.1230035	2026-07-03 21:23:57.362856
1331	7	183	26.3790461	50.1228846	2026-07-03 21:23:58.409063
1332	7	183	26.3796617	50.1227098	2026-07-03 21:24:02.356544
1333	7	183	26.3800691	50.1225911	2026-07-03 21:24:03.484149
1334	7	183	26.3806918	50.1224138	2026-07-03 21:24:07.32713
1335	7	183	26.3810905	50.1222928	2026-07-03 21:24:08.569701
1336	7	183	26.3816856	50.12211	2026-07-03 21:24:12.356276
1337	7	183	26.3820837	50.1219799	2026-07-03 21:24:13.41808
1338	7	183	26.3826744	50.1217879	2026-07-03 21:24:17.461257
1339	7	183	26.3830803	50.1216716	2026-07-03 21:24:18.361879
1340	7	183	26.3836906	50.1214855	2026-07-03 21:24:22.334766
1341	7	183	26.3841019	50.121364	2026-07-03 21:24:23.402443
1342	7	183	26.38472	50.1211623	2026-07-03 21:24:27.268003
1343	7	183	26.3851274	50.1210219	2026-07-03 21:24:28.451637
1344	7	183	26.3857664	50.1208092	2026-07-03 21:24:32.575179
1345	7	183	26.3861973	50.1206727	2026-07-03 21:24:33.816724
1346	7	183	26.3873209	50.1203277	2026-07-03 21:24:41.665186
1351	7	183	26.3903192	50.1194349	2026-07-03 21:24:52.188444
1354	7	183	26.3919219	50.1189655	2026-07-03 21:24:58.147246
1359	7	183	26.3946269	50.1181617	2026-07-03 21:25:12.109515
1364	7	183	26.3970881	50.1174062	2026-07-03 21:25:23.198399
1365	7	183	26.3977025	50.1172237	2026-07-03 21:25:27.139287
1369	7	183	26.3995549	50.1164903	2026-07-03 21:25:37.106606
1370	7	183	26.3998774	50.1163253	2026-07-03 21:25:38.254681
1374	7	183	26.4008858	50.1159182	2026-07-03 21:25:48.266248
1375	7	183	26.4012117	50.1157564	2026-07-03 21:25:52.095931
1376	7	183	26.4014362	50.115639	2026-07-03 21:25:53.619233
1377	7	183	26.4017465	50.1154839	2026-07-03 21:25:57.307626
1380	7	183	26.4020445	50.1154324	2026-07-03 21:26:03.477591
1381	7	183	26.4020716	50.1155877	2026-07-03 21:26:07.307336
1383	7	183	26.4018544	50.1159711	2026-07-03 21:26:12.372328
1385	7	183	26.4016461	50.1163773	2026-07-03 21:26:17.342137
1386	7	183	26.4015738	50.1165299	2026-07-03 21:26:18.45308
1387	7	183	26.4014764	50.1166941	2026-07-03 21:26:22.388578
1388	7	183	26.4014346	50.1167694	2026-07-03 21:26:23.501358
1389	7	183	26.4013882	50.1168587	2026-07-03 21:26:27.30856
1390	7	183	26.4013517	50.1169262	2026-07-03 21:26:28.435232
1395	7	183	26.4010692	50.1174222	2026-07-03 21:26:42.658235
1396	7	183	26.4010512	50.1174634	2026-07-03 21:26:43.364394
1397	7	183	26.4010512	50.1174634	2026-07-03 21:26:47.315383
1399	7	183	26.4009259	50.1177143	2026-07-03 21:26:52.298522
1404	7	183	26.4003037	50.1187693	2026-07-03 21:27:17.075529
1405	7	183	26.4001085	50.11862	2026-07-03 21:27:22.11996
1407	7	183	26.3997975	50.1184217	2026-07-03 21:27:32.05805
1410	7	183	26.3998284	50.1182049	2026-07-03 21:27:48.235453
1347	7	183	26.3880071	50.1201204	2026-07-03 21:24:42.285464
1348	7	183	26.3884655	50.1199847	2026-07-03 21:24:43.448043
1350	7	183	26.3896271	50.1196353	2026-07-03 21:24:48.368485
1353	7	183	26.391465	50.1190965	2026-07-03 21:24:57.139941
1355	7	183	26.392585	50.1187762	2026-07-03 21:25:02.459377
1356	7	183	26.3930153	50.1186509	2026-07-03 21:25:03.261511
1357	7	183	26.3936275	50.1184601	2026-07-03 21:25:07.107444
1358	7	183	26.3940343	50.1183348	2026-07-03 21:25:08.223511
1360	7	183	26.3950185	50.118038	2026-07-03 21:25:13.510899
1361	7	183	26.3956272	50.1178446	2026-07-03 21:25:17.069014
1362	7	183	26.3960471	50.1177141	2026-07-03 21:25:18.205053
1367	7	183	26.3986725	50.1168826	2026-07-03 21:25:32.105298
1368	7	183	26.3990325	50.116728	2026-07-03 21:25:33.213863
1371	7	183	26.4002592	50.1161523	2026-07-03 21:25:42.089153
1372	7	183	26.4004464	50.11609	2026-07-03 21:25:43.289782
1373	7	183	26.4006962	50.116002	2026-07-03 21:25:47.131807
1379	7	183	26.4020107	50.1154038	2026-07-03 21:26:02.340051
1382	7	183	26.401999	50.1157287	2026-07-03 21:26:08.469936
1391	7	183	26.4013031	50.1170054	2026-07-03 21:26:32.287647
1393	7	183	26.401236	50.1171185	2026-07-03 21:26:37.327885
1394	7	183	26.4011796	50.1172293	2026-07-03 21:26:38.340093
1398	7	183	26.4009259	50.1177143	2026-07-03 21:26:48.511239
1400	7	183	26.4007496	50.1180243	2026-07-03 21:26:57.087862
1401	7	183	26.4005971	50.1183135	2026-07-03 21:27:02.115566
1403	7	183	26.4004054	50.118719	2026-07-03 21:27:12.124411
1406	7	183	26.3999401	50.1185118	2026-07-03 21:27:27.144207
1408	7	183	26.3998307	50.118319	2026-07-03 21:27:37.054839
1409	7	183	26.3998439	50.1182441	2026-07-03 21:27:42.088785
1349	7	183	26.3891556	50.119774	2026-07-03 21:24:47.273056
1352	7	183	26.3907758	50.1193018	2026-07-03 21:24:53.32677
1363	7	183	26.3966737	50.1175306	2026-07-03 21:25:22.119322
1366	7	183	26.3981004	50.1170915	2026-07-03 21:25:28.212461
1378	7	183	26.4019012	50.1154117	2026-07-03 21:25:58.534918
1384	7	183	26.4017646	50.1161388	2026-07-03 21:26:13.490913
1392	7	183	26.4012902	50.1170293	2026-07-03 21:26:33.39187
1402	7	183	26.4004898	50.1185661	2026-07-03 21:27:07.117901
1411	7	184	26.3794719	50.1172546	2026-07-05 21:50:29.989513
1412	7	184	26.3795092	50.1173941	2026-07-05 21:50:31.90684
1413	7	184	26.3795636	50.1177222	2026-07-05 21:50:34.574967
1414	7	184	26.3795785	50.1178241	2026-07-05 21:50:37.234276
1415	7	184	26.3796065	50.1179811	2026-07-05 21:50:39.703413
1416	7	184	26.3796238	50.1181249	2026-07-05 21:50:41.913958
1417	7	184	26.3796644	50.1184003	2026-07-05 21:50:44.881429
1418	7	184	26.3796947	50.1185966	2026-07-05 21:50:46.914802
1419	7	184	26.3797291	50.1188162	2026-07-05 21:50:49.882826
1420	7	184	26.3797377	50.1188949	2026-07-05 21:50:51.925072
1421	7	184	26.3797558	50.1190211	2026-07-05 21:50:54.643151
1422	7	184	26.3797872	50.1191627	2026-07-05 21:50:56.877499
1423	7	184	26.3798506	50.1193863	2026-07-05 21:50:59.699355
1424	7	184	26.3798767	50.1195444	2026-07-05 21:51:01.907222
1425	7	184	26.3798968	50.1197673	2026-07-05 21:51:04.725601
1426	7	184	26.3799224	50.1199397	2026-07-05 21:51:06.874803
1427	7	184	26.3799538	50.1201796	2026-07-05 21:51:09.706705
1428	7	184	26.3799651	50.120275	2026-07-05 21:51:11.912626
1429	7	184	26.3799912	50.120457	2026-07-05 21:51:14.743245
1430	7	184	26.3800252	50.1206195	2026-07-05 21:51:16.878799
1431	7	184	26.3800664	50.1208592	2026-07-05 21:51:19.707377
1432	7	184	26.3800863	50.1209966	2026-07-05 21:51:21.9399
1433	7	184	26.3800256	50.1211385	2026-07-05 21:51:24.660071
1434	7	184	26.3799113	50.1211837	2026-07-05 21:51:26.898227
1435	7	184	26.3797013	50.1212419	2026-07-05 21:51:29.788624
1436	7	184	26.3795583	50.1212765	2026-07-05 21:51:31.891363
1437	7	184	26.3793532	50.1213148	2026-07-05 21:51:34.676636
1438	7	184	26.3792234	50.1213505	2026-07-05 21:51:37.466532
1439	7	184	26.378572	50.1216187	2026-07-05 21:52:48.331969
1440	7	184	26.3784987	50.1215695	2026-07-05 21:53:14.766956
1441	7	184	26.3784987	50.1215695	2026-07-05 21:53:19.87475
1442	7	184	26.3784987	50.1215695	2026-07-05 21:53:24.747471
1443	7	184	26.3784987	50.1215695	2026-07-05 21:53:29.767666
1444	7	184	26.3784987	50.1215695	2026-07-05 21:53:34.808572
1445	7	184	26.3784987	50.1215695	2026-07-05 21:53:39.817413
1446	7	184	26.3784978	50.1215676	2026-07-05 21:53:45.098011
1447	7	184	26.3784978	50.12157	2026-07-05 21:53:49.938632
1448	7	184	26.3784978	50.12157	2026-07-05 21:53:54.959246
1449	7	184	26.3784978	50.12157	2026-07-05 21:53:59.996029
1450	7	184	26.3784978	50.12157	2026-07-05 21:54:05.065594
1451	7	184	26.3784978	50.12157	2026-07-05 21:54:10.139906
1452	7	184	26.3784978	50.12157	2026-07-05 21:54:15.080615
1453	7	184	26.3784978	50.12157	2026-07-05 21:54:19.915417
1454	7	184	26.3784978	50.12157	2026-07-05 21:54:24.858018
1455	7	184	26.3784978	50.12157	2026-07-05 21:54:30.016373
1456	7	184	26.3784978	50.12157	2026-07-05 21:54:35.084171
1457	7	184	26.3784978	50.12157	2026-07-05 21:54:39.95696
1458	7	184	26.3784978	50.12157	2026-07-05 21:54:44.974878
1459	7	184	26.3784924	50.1215695	2026-07-05 21:54:49.753323
1460	7	184	26.3784924	50.1215695	2026-07-05 21:54:49.954295
1461	7	184	26.3784131	50.1216035	2026-07-05 21:54:55.03371
1462	7	184	26.378384	50.1216149	2026-07-05 21:54:55.651051
1463	7	184	26.3781908	50.1216616	2026-07-05 21:54:59.968581
1464	7	184	26.378134	50.1216821	2026-07-05 21:55:00.613446
1465	7	184	26.3779364	50.1217457	2026-07-05 21:55:04.934985
1466	7	184	26.3778787	50.1217603	2026-07-05 21:55:05.616299
1467	7	184	26.377657	50.121793	2026-07-05 21:55:10.086482
1468	7	184	26.3776131	50.1217949	2026-07-05 21:55:10.855583
1469	7	184	26.377448	50.1218449	2026-07-05 21:55:14.979938
1470	7	184	26.3774075	50.121859	2026-07-05 21:55:15.670918
1471	7	184	26.3771719	50.1219357	2026-07-05 21:55:19.987908
1472	7	184	26.3771021	50.1219512	2026-07-05 21:55:20.649307
1473	7	184	26.3768681	50.1220208	2026-07-05 21:55:25.062614
1474	7	184	26.3768039	50.1220369	2026-07-05 21:55:26.079867
1475	7	184	26.3766208	50.1220674	2026-07-05 21:55:30.085265
1476	7	184	26.3765978	50.1220513	2026-07-05 21:55:30.773709
1477	7	184	26.3765651	50.1218968	2026-07-05 21:55:34.953251
1478	7	184	26.3765776	50.1218312	2026-07-05 21:55:35.679488
1479	7	184	26.376649	50.1215222	2026-07-05 21:55:39.952697
1480	7	184	26.3766634	50.1214363	2026-07-05 21:55:40.573382
1481	7	184	26.3767375	50.1210533	2026-07-05 21:55:44.764601
1482	7	184	26.3767477	50.1209475	2026-07-05 21:55:45.4015
1483	7	184	26.3768014	50.1205347	2026-07-05 21:55:49.805606
1484	7	184	26.3768163	50.12043	2026-07-05 21:55:50.453218
1485	7	184	26.3768665	50.120049	2026-07-05 21:55:54.788493
1486	7	184	26.3768741	50.1199618	2026-07-05 21:55:55.408124
1487	7	184	26.3769093	50.1196928	2026-07-05 21:55:59.748314
1488	7	184	26.3769157	50.1196446	2026-07-05 21:56:00.440332
1489	7	184	26.3768772	50.119555	2026-07-05 21:56:04.778699
1490	7	184	26.3768576	50.1195515	2026-07-05 21:56:05.483819
1491	7	184	26.376805	50.1196769	2026-07-05 21:56:09.813864
1492	7	184	26.3768098	50.1197421	2026-07-05 21:56:10.439859
1493	7	184	26.3767778	50.1200473	2026-07-05 21:56:14.782287
1494	7	184	26.376766	50.1201397	2026-07-05 21:56:15.423618
1495	7	184	26.3766974	50.1205663	2026-07-05 21:56:19.768924
1496	7	184	26.376682	50.1206787	2026-07-05 21:56:20.461039
1497	7	184	26.3766083	50.1211252	2026-07-05 21:56:24.740536
1498	7	184	26.3765873	50.1212298	2026-07-05 21:56:25.470595
1499	7	184	26.3765282	50.1216239	2026-07-05 21:56:29.761069
1500	7	184	26.3765128	50.1217153	2026-07-05 21:56:30.427981
1501	7	184	26.3764452	50.1220895	2026-07-05 21:56:34.773393
1502	7	184	26.3764435	50.1221819	2026-07-05 21:56:35.542427
1503	7	184	26.3764446	50.1225136	2026-07-05 21:56:39.743135
1504	7	184	26.3764355	50.1225689	2026-07-05 21:56:40.452512
1505	7	184	26.3763831	50.122618	2026-07-05 21:56:50.031697
1506	7	184	26.3763831	50.122618	2026-07-05 21:56:54.857556
1507	7	184	26.3763831	50.122618	2026-07-05 21:56:59.920489
1508	7	184	26.3763831	50.122618	2026-07-05 21:57:04.946135
1509	7	184	26.3763831	50.122618	2026-07-05 21:57:09.946994
1510	7	184	26.3763831	50.122618	2026-07-05 21:57:16.605772
1513	7	184	26.3763831	50.122618	2026-07-05 21:57:29.962173
1514	7	184	26.3763831	50.122618	2026-07-05 21:57:34.984894
1511	7	184	26.3763831	50.122618	2026-07-05 21:57:19.98895
1512	7	184	26.3763831	50.122618	2026-07-05 21:57:24.932297
1515	7	184	26.3763831	50.122618	2026-07-05 21:57:39.911198
1516	7	184	26.3763831	50.122618	2026-07-05 21:57:45.025848
1517	7	184	26.3763831	50.122618	2026-07-05 21:57:49.762984
1518	14	189	26.3784812	50.1213538	2026-07-06 20:25:31.326477
1519	14	189	26.3784742	50.1213435	2026-07-06 20:25:36.282202
1520	14	189	26.3784829	50.1213386	2026-07-06 20:25:41.438552
1521	14	189	26.3784843	50.1213357	2026-07-06 20:25:46.291474
1522	14	189	26.3784834	50.1213215	2026-07-06 20:25:51.236631
1523	14	189	26.3784769	50.1213148	2026-07-06 20:25:56.379519
1524	14	189	26.3791499	50.1213455	2026-07-06 20:27:27.150898
1525	14	189	26.3793873	50.1212678	2026-07-06 20:27:31.208232
1526	14	189	26.3793873	50.1212678	2026-07-06 20:27:31.468263
1527	14	189	26.3797463	50.121213	2026-07-06 20:27:36.390781
1528	14	189	26.3797463	50.121213	2026-07-06 20:27:36.818354
1529	14	189	26.380051	50.1211528	2026-07-06 20:27:41.277617
1530	14	189	26.380051	50.1211528	2026-07-06 20:27:41.510551
1531	14	189	26.3801774	50.1214164	2026-07-06 20:27:46.34312
1532	14	189	26.3801774	50.1214164	2026-07-06 20:27:46.487886
1533	14	189	26.3802246	50.1218358	2026-07-06 20:27:51.237763
1534	14	189	26.3802246	50.1218358	2026-07-06 20:27:51.599676
1535	14	189	26.3801439	50.1220697	2026-07-06 20:27:56.208792
1536	14	189	26.3801439	50.1220697	2026-07-06 20:27:56.489549
1537	14	189	26.3797494	50.1222194	2026-07-06 20:28:01.013273
1538	14	189	26.3797494	50.1222194	2026-07-06 20:28:01.804562
1539	14	189	26.3792086	50.1223687	2026-07-06 20:28:12.711642
1540	14	189	26.3786967	50.1225451	2026-07-06 20:28:12.80614
1541	14	189	26.3786967	50.1225451	2026-07-06 20:28:12.821758
1542	14	189	26.3792086	50.1223687	2026-07-06 20:28:12.821758
1543	14	189	26.378073	50.1227779	2026-07-06 20:28:16.221237
1544	14	189	26.378073	50.1227779	2026-07-06 20:28:16.48906
1545	14	189	26.3773319	50.1230396	2026-07-06 20:28:21.268082
1546	14	189	26.3773319	50.1230396	2026-07-06 20:28:21.567961
1547	14	189	26.3765006	50.1232953	2026-07-06 20:28:26.543278
1548	14	189	26.3765006	50.1232953	2026-07-06 20:28:27.043325
1549	14	189	26.3756352	50.1235389	2026-07-06 20:28:32.138941
1550	14	189	26.3756352	50.1235389	2026-07-06 20:28:32.889256
1551	14	189	26.3747787	50.1237852	2026-07-06 20:28:36.013844
1552	14	189	26.3747787	50.1237852	2026-07-06 20:28:36.220382
1553	14	189	26.3739589	50.1240307	2026-07-06 20:28:40.951135
1554	14	189	26.3739589	50.1240307	2026-07-06 20:28:41.389098
1555	14	189	26.3731324	50.1242674	2026-07-06 20:28:45.982368
1556	14	189	26.3731324	50.1242674	2026-07-06 20:28:46.206335
1557	14	189	26.3722632	50.1245301	2026-07-06 20:28:50.967777
1558	14	189	26.3722632	50.1245301	2026-07-06 20:28:51.19532
1559	14	189	26.3713316	50.1248016	2026-07-06 20:28:56.119984
1560	14	189	26.3713316	50.1248016	2026-07-06 20:28:56.21078
1561	14	189	26.3703562	50.1250849	2026-07-06 20:29:00.999012
1562	14	189	26.3703562	50.1250849	2026-07-06 20:29:01.3571
1563	14	189	26.3694095	50.1253753	2026-07-06 20:29:06.028815
1564	14	189	26.3694095	50.1253753	2026-07-06 20:29:06.30065
1565	14	189	26.3684276	50.1256623	2026-07-06 20:29:11.079255
1566	14	189	26.3684276	50.1256623	2026-07-06 20:29:11.349929
1567	14	189	26.3674164	50.1259711	2026-07-06 20:29:16.267308
1568	14	189	26.3674164	50.1259711	2026-07-06 20:29:16.398129
1569	14	189	26.3663815	50.1262785	2026-07-06 20:29:20.972577
1570	14	189	26.3663815	50.1262785	2026-07-06 20:29:21.273521
1571	14	189	26.3653801	50.1266299	2026-07-06 20:29:26.119083
1572	14	189	26.3653801	50.1266299	2026-07-06 20:29:26.319692
1573	14	189	26.3644199	50.1270442	2026-07-06 20:29:31.243252
1574	14	189	26.3644199	50.1270442	2026-07-06 20:29:31.306943
1575	14	189	26.3634801	50.127505	2026-07-06 20:29:36.005393
1576	14	189	26.3634801	50.127505	2026-07-06 20:29:36.289837
1577	14	189	26.3625426	50.1280659	2026-07-06 20:29:41.105804
1578	14	189	26.3625426	50.1280659	2026-07-06 20:29:41.324403
1579	14	189	26.3616325	50.1286798	2026-07-06 20:29:46.05966
1580	14	189	26.3616325	50.1286798	2026-07-06 20:29:46.295324
1581	14	189	26.3607596	50.1293549	2026-07-06 20:29:50.989583
1582	14	189	26.3607596	50.1293549	2026-07-06 20:29:51.29251
1583	14	189	26.3599231	50.1300627	2026-07-06 20:29:55.988388
1584	14	189	26.3599231	50.1300627	2026-07-06 20:29:56.263886
1585	14	189	26.3591481	50.1308073	2026-07-06 20:30:01.012098
1586	14	189	26.3591481	50.1308073	2026-07-06 20:30:01.281959
1587	14	189	26.3583747	50.131627	2026-07-06 20:30:05.969062
1588	14	189	26.3583747	50.131627	2026-07-06 20:30:06.3248
1589	14	189	26.357551	50.1324138	2026-07-06 20:30:10.938604
1590	14	189	26.357551	50.1324138	2026-07-06 20:30:11.224486
1591	14	189	26.3567528	50.1331494	2026-07-06 20:30:15.998258
1592	14	189	26.3567528	50.1331494	2026-07-06 20:30:16.305336
1593	14	189	26.355906	50.1336745	2026-07-06 20:30:21.282047
1594	14	189	26.355906	50.1336745	2026-07-06 20:30:21.387513
1595	14	189	26.3549487	50.133785	2026-07-06 20:30:25.975282
1596	14	189	26.3549487	50.133785	2026-07-06 20:30:26.418297
1597	14	189	26.3539643	50.1337462	2026-07-06 20:30:31.29926
1598	14	189	26.3539643	50.1337462	2026-07-06 20:30:31.496452
1599	14	189	26.353063	50.1337088	2026-07-06 20:30:36.021267
1600	14	189	26.353063	50.1337088	2026-07-06 20:30:36.240297
1601	14	189	26.3523391	50.1335876	2026-07-06 20:30:40.99074
1602	14	189	26.3523391	50.1335876	2026-07-06 20:30:41.291882
1603	14	189	26.3517042	50.1332694	2026-07-06 20:30:45.997098
1604	14	189	26.3517042	50.1332694	2026-07-06 20:30:46.263753
1605	14	189	26.3512167	50.1327958	2026-07-06 20:30:51.191252
1606	14	189	26.3512167	50.1327958	2026-07-06 20:30:51.276361
1607	14	189	26.3509026	50.1322378	2026-07-06 20:30:56.010845
1608	14	189	26.3509026	50.1322378	2026-07-06 20:30:56.29332
1609	14	189	26.3506018	50.1316276	2026-07-06 20:31:01.038353
1610	14	189	26.3506018	50.1316276	2026-07-06 20:31:01.241903
1611	14	189	26.3502879	50.1309773	2026-07-06 20:31:06.009677
1612	14	189	26.3502879	50.1309773	2026-07-06 20:31:06.262009
1613	14	189	26.349995	50.1302006	2026-07-06 20:31:10.988899
1614	14	189	26.349995	50.1302006	2026-07-06 20:31:11.243488
1615	14	189	26.3497012	50.1293487	2026-07-06 20:31:16.113158
1616	14	189	26.3497012	50.1293487	2026-07-06 20:31:16.495204
1617	14	189	26.3494149	50.128419	2026-07-06 20:31:21.129423
1618	14	189	26.3494149	50.128419	2026-07-06 20:31:21.313884
1619	14	189	26.3491295	50.1274431	2026-07-06 20:31:25.995617
1620	14	189	26.3491295	50.1274431	2026-07-06 20:31:26.264178
1622	14	189	26.348826	50.1264645	2026-07-06 20:31:31.296543
1623	14	189	26.3485035	50.1254873	2026-07-06 20:31:36.019465
1624	14	189	26.3485035	50.1254873	2026-07-06 20:31:36.39108
1625	14	189	26.3481368	50.124556	2026-07-06 20:31:41.027746
1627	14	189	26.3477628	50.1236774	2026-07-06 20:31:45.944712
1628	14	189	26.3477628	50.1236774	2026-07-06 20:31:46.36986
1629	14	189	26.3474262	50.122862	2026-07-06 20:31:50.912092
1632	14	189	26.3470833	50.1219911	2026-07-06 20:31:56.301987
1633	14	189	26.3467418	50.1211738	2026-07-06 20:32:00.913684
1634	14	189	26.3467418	50.1211738	2026-07-06 20:32:01.217096
1635	14	189	26.3464149	50.120442	2026-07-06 20:32:05.958965
1636	14	189	26.3464149	50.120442	2026-07-06 20:32:06.219372
1637	14	189	26.3462448	50.1200629	2026-07-06 20:32:10.937883
1638	14	189	26.3462448	50.1200629	2026-07-06 20:32:11.276183
1639	14	189	26.346004	50.1198849	2026-07-06 20:32:16.027713
1640	14	189	26.346004	50.1198849	2026-07-06 20:32:16.233124
1642	14	189	26.3455571	50.1200367	2026-07-06 20:32:21.359026
1643	14	189	26.3449972	50.1202947	2026-07-06 20:32:26.010939
1646	14	189	26.3444673	50.1205551	2026-07-06 20:32:31.261728
1648	14	189	26.3438324	50.1208252	2026-07-06 20:32:36.200635
1649	14	189	26.3431158	50.121145	2026-07-06 20:32:41.040388
1650	14	189	26.3431158	50.121145	2026-07-06 20:32:41.218638
1652	14	189	26.3423403	50.1214881	2026-07-06 20:32:46.259
1654	14	189	26.3415725	50.1218227	2026-07-06 20:32:51.222013
1655	14	189	26.3409063	50.1221113	2026-07-06 20:32:55.996573
1656	14	189	26.3409063	50.1221113	2026-07-06 20:32:56.24509
1657	14	189	26.3403391	50.1223656	2026-07-06 20:33:00.925099
1658	14	189	26.3403391	50.1223656	2026-07-06 20:33:01.260776
1659	14	189	26.3398912	50.1225588	2026-07-06 20:33:05.970314
1664	14	189	26.3396045	50.1226793	2026-07-06 20:33:21.248753
1666	14	189	26.3396045	50.1226793	2026-07-06 20:33:31.571983
1667	14	189	26.3396045	50.1226793	2026-07-06 20:33:36.450974
1668	14	189	26.3396045	50.1226793	2026-07-06 20:33:41.437703
1670	14	189	26.3395384	50.1226934	2026-07-06 20:33:47.190623
1672	14	189	26.3391963	50.1228621	2026-07-06 20:33:52.16186
1673	14	189	26.3388174	50.123035	2026-07-06 20:33:56.547453
1674	14	189	26.3387114	50.1230805	2026-07-06 20:33:57.22925
1675	14	189	26.3382359	50.1232788	2026-07-06 20:34:01.430795
1676	14	189	26.3381197	50.1233258	2026-07-06 20:34:02.219248
1679	14	189	26.3372622	50.1237372	2026-07-06 20:34:11.523466
1681	14	189	26.337042	50.1238344	2026-07-06 20:34:16.465859
1682	14	189	26.3370178	50.1238446	2026-07-06 20:34:17.32622
1683	14	189	26.3369867	50.1238539	2026-07-06 20:34:21.501193
1684	14	189	26.3369867	50.123854	2026-07-06 20:34:26.6342
1685	14	189	26.3369867	50.123854	2026-07-06 20:34:31.413233
1686	14	189	26.3369867	50.123854	2026-07-06 20:34:36.53972
1691	14	189	26.3369144	50.1238765	2026-07-06 20:34:57.132196
1693	14	189	26.3365717	50.1240448	2026-07-06 20:35:02.217532
1694	14	189	26.3361507	50.124217	2026-07-06 20:35:06.472508
1696	14	189	26.3354948	50.1244973	2026-07-06 20:35:11.489949
1698	14	189	26.3347743	50.1248243	2026-07-06 20:35:16.498752
1700	14	189	26.3340154	50.1251609	2026-07-06 20:35:21.53065
1701	14	189	26.3338658	50.1252273	2026-07-06 20:35:22.227137
1703	14	189	26.3330939	50.1255557	2026-07-06 20:35:27.155088
1705	14	189	26.3322884	50.125909	2026-07-06 20:35:32.303201
1706	14	189	26.3316389	50.1261825	2026-07-06 20:35:36.540151
1711	14	189	26.3300683	50.1264832	2026-07-06 20:35:47.137734
1712	14	189	26.329697	50.126365	2026-07-06 20:35:51.489807
1713	14	189	26.3296512	50.1262894	2026-07-06 20:35:52.220312
1714	14	189	26.3295754	50.1258335	2026-07-06 20:35:56.439647
1716	14	189	26.3294948	50.1251838	2026-07-06 20:36:01.50266
1718	14	189	26.3294049	50.124503	2026-07-06 20:36:06.454447
1719	14	189	26.3293932	50.1243742	2026-07-06 20:36:07.230696
1721	14	189	26.3295263	50.1238148	2026-07-06 20:36:12.201089
1722	14	189	26.3297352	50.1235826	2026-07-06 20:36:16.50782
1728	14	189	26.3299263	50.1235109	2026-07-06 20:36:36.48497
1729	14	189	26.3299958	50.1234909	2026-07-06 20:36:39.145074
1732	14	189	26.3305129	50.1232159	2026-07-06 20:36:46.457547
1733	14	189	26.3307002	50.1229721	2026-07-06 20:36:49.228669
1736	14	189	26.3311452	50.122175	2026-07-06 20:36:56.46776
1737	14	189	26.3314016	50.1219021	2026-07-06 20:36:59.191998
1738	14	189	26.3316139	50.1217644	2026-07-06 20:37:01.491598
1740	14	189	26.3322361	50.1214635	2026-07-06 20:37:06.479788
1743	14	189	26.3331575	50.1212613	2026-07-06 20:37:14.293825
1745	14	189	26.333342	50.1215123	2026-07-06 20:37:19.152517
1746	14	189	26.333319	50.1216555	2026-07-06 20:37:21.507537
1749	14	189	26.3330553	50.1225104	2026-07-06 20:37:29.278878
1752	14	189	26.3329593	50.1234179	2026-07-06 20:37:36.291195
1753	14	189	26.3330826	50.1238371	2026-07-06 20:37:39.098018
1755	14	189	26.3335419	50.124362	2026-07-06 20:37:43.993793
1758	14	189	26.3344558	50.1244731	2026-07-06 20:37:51.27634
1760	14	189	26.335113	50.1241208	2026-07-06 20:37:56.295671
1761	14	189	26.3354918	50.1238353	2026-07-06 20:37:58.939684
1766	14	189	26.3367129	50.1224405	2026-07-06 20:38:11.296159
1768	14	189	26.3370347	50.1218411	2026-07-06 20:38:16.307783
1769	14	189	26.3371919	50.1214667	2026-07-06 20:38:18.958999
1772	14	189	26.3374882	50.1205545	2026-07-06 20:38:26.229341
1776	14	189	26.3375664	50.1193344	2026-07-06 20:38:36.474534
1778	14	189	26.3372696	50.1187961	2026-07-06 20:38:41.448322
1621	14	189	26.348826	50.1264645	2026-07-06 20:31:31.26431
1641	14	189	26.3455571	50.1200367	2026-07-06 20:32:21.099984
1644	14	189	26.3449972	50.1202947	2026-07-06 20:32:26.212377
1647	14	189	26.3438324	50.1208252	2026-07-06 20:32:35.905237
1660	14	189	26.3398912	50.1225588	2026-07-06 20:33:06.228604
1677	14	189	26.3376651	50.1235396	2026-07-06 20:34:06.532704
1680	14	189	26.3371976	50.1237632	2026-07-06 20:34:12.25579
1689	14	189	26.3369867	50.123854	2026-07-06 20:34:51.562192
1704	14	189	26.3324506	50.1258401	2026-07-06 20:35:31.440778
1709	14	189	26.3307273	50.1263899	2026-07-06 20:35:42.177135
1720	14	189	26.3294731	50.1239103	2026-07-06 20:36:11.487864
1730	14	189	26.3301378	50.1234454	2026-07-06 20:36:41.48247
1748	14	189	26.3331477	50.1221476	2026-07-06 20:37:26.459698
1763	14	189	26.3360563	50.123301	2026-07-06 20:38:04.029524
1774	14	189	26.3376192	50.1199368	2026-07-06 20:38:31.253863
1777	14	189	26.3374175	50.1189901	2026-07-06 20:38:39.203567
1626	14	189	26.3481368	50.124556	2026-07-06 20:31:41.274759
1630	14	189	26.3474262	50.122862	2026-07-06 20:31:51.293554
1631	14	189	26.3470833	50.1219911	2026-07-06 20:31:56.059604
1645	14	189	26.3444673	50.1205551	2026-07-06 20:32:31.130018
1651	14	189	26.3423403	50.1214881	2026-07-06 20:32:45.995119
1653	14	189	26.3415725	50.1218227	2026-07-06 20:32:50.880227
1661	14	189	26.3396272	50.1226735	2026-07-06 20:33:11.045748
1662	14	189	26.3396272	50.1226735	2026-07-06 20:33:11.258591
1663	14	189	26.3396045	50.1226793	2026-07-06 20:33:16.289786
1665	14	189	26.3396045	50.1226793	2026-07-06 20:33:26.263703
1669	14	189	26.3395746	50.1226823	2026-07-06 20:33:46.478111
1671	14	189	26.33928	50.1228198	2026-07-06 20:33:51.451547
1678	14	189	26.3375664	50.1235944	2026-07-06 20:34:07.247374
1687	14	189	26.3369867	50.123854	2026-07-06 20:34:41.496042
1688	14	189	26.3369867	50.123854	2026-07-06 20:34:46.528345
1690	14	189	26.3369526	50.1238643	2026-07-06 20:34:56.457301
1692	14	189	26.3366588	50.1240024	2026-07-06 20:35:01.540125
1695	14	189	26.3360206	50.124271	2026-07-06 20:35:07.170348
1697	14	189	26.3353538	50.1245601	2026-07-06 20:35:12.248534
1699	14	189	26.3346228	50.1248943	2026-07-06 20:35:17.196256
1702	14	189	26.3332504	50.1254932	2026-07-06 20:35:26.532227
1707	14	189	26.3314818	50.1262417	2026-07-06 20:35:37.279383
1708	14	189	26.3308697	50.1263675	2026-07-06 20:35:41.455275
1710	14	189	26.3301905	50.1264661	2026-07-06 20:35:46.450973
1715	14	189	26.3295576	50.1257048	2026-07-06 20:35:57.109888
1717	14	189	26.329479	50.1250496	2026-07-06 20:36:02.172345
1723	14	189	26.3297784	50.1235601	2026-07-06 20:36:17.167641
1724	14	189	26.3298929	50.1235136	2026-07-06 20:36:21.457412
1725	14	189	26.3298991	50.1235144	2026-07-06 20:36:22.201645
1726	14	189	26.3299048	50.1235155	2026-07-06 20:36:26.540234
1727	14	189	26.3299048	50.1235156	2026-07-06 20:36:31.6802
1731	14	189	26.3303739	50.1233307	2026-07-06 20:36:44.212234
1734	14	189	26.3308162	50.1227481	2026-07-06 20:36:51.453645
1735	14	189	26.3309994	50.1223909	2026-07-06 20:36:54.202312
1739	14	189	26.3319807	50.121576	2026-07-06 20:37:04.145907
1741	14	189	26.3326204	50.1213354	2026-07-06 20:37:09.240702
1742	14	189	26.3328631	50.1212778	2026-07-06 20:37:11.431795
1744	14	189	26.3332825	50.121352	2026-07-06 20:37:16.472158
1747	14	189	26.333226	50.1219271	2026-07-06 20:37:24.157824
1750	14	189	26.3329991	50.1227538	2026-07-06 20:37:31.60908
1751	14	189	26.3329434	50.1231431	2026-07-06 20:37:33.97865
1754	14	189	26.3332405	50.1240867	2026-07-06 20:37:41.284637
1756	14	189	26.3337814	50.1244865	2026-07-06 20:37:46.266231
1757	14	189	26.3341787	50.1245179	2026-07-06 20:37:48.9534
1759	14	189	26.3348512	50.1242869	2026-07-06 20:37:54.05415
1762	14	189	26.3357232	50.1236326	2026-07-06 20:38:01.254835
1764	14	189	26.3362595	50.1230572	2026-07-06 20:38:06.248769
1765	14	189	26.3365427	50.1226862	2026-07-06 20:38:08.926142
1767	14	189	26.336921	50.1220773	2026-07-06 20:38:13.940614
1770	14	189	26.3372878	50.1212043	2026-07-06 20:38:21.283067
1771	14	189	26.3374143	50.1208166	2026-07-06 20:38:23.929524
1773	14	189	26.3375774	50.1201773	2026-07-06 20:38:28.960947
1775	14	189	26.3376148	50.1195714	2026-07-06 20:38:34.202415
1779	14	189	26.3370112	50.1185683	2026-07-06 20:38:44.36709
1780	14	189	26.3368358	50.1184721	2026-07-06 20:38:46.675984
1781	14	189	26.3365525	50.1183855	2026-07-06 20:38:49.387775
1782	14	189	26.3363509	50.1183687	2026-07-06 20:38:51.494076
1783	14	189	26.3357477	50.1185292	2026-07-06 20:38:59.32327
1784	14	189	26.3354409	50.1187282	2026-07-06 20:39:04.241968
1785	14	189	26.3352397	50.1189198	2026-07-06 20:39:09.196948
1786	14	189	26.3351788	50.1190197	2026-07-06 20:39:14.225634
1787	14	189	26.3351675	50.1190325	2026-07-06 20:41:10.478617
1788	14	189	26.3351675	50.1190325	2026-07-06 20:41:15.500341
1789	14	189	26.3351672	50.1190321	2026-07-06 20:41:20.492068
1790	14	189	26.3351951	50.1190106	2026-07-06 20:41:25.525299
1791	14	189	26.3351954	50.1190102	2026-07-06 20:41:30.479129
1792	14	189	26.3352081	50.1190049	2026-07-06 20:41:35.494515
1793	14	189	26.3351898	50.1189976	2026-07-06 20:41:40.462456
1794	14	189	26.3350727	50.1190507	2026-07-06 20:41:43.967601
1795	14	189	26.3350259	50.1190858	2026-07-06 20:41:45.492231
1796	14	189	26.3347853	50.1192749	2026-07-06 20:41:48.948397
1797	14	189	26.334709	50.1193407	2026-07-06 20:41:50.516427
1798	14	189	26.3344021	50.1196388	2026-07-06 20:41:53.963359
1799	14	189	26.3343292	50.1197279	2026-07-06 20:41:55.458959
1800	14	189	26.3340333	50.1201021	2026-07-06 20:41:58.965761
1801	14	189	26.3339631	50.1201926	2026-07-06 20:42:00.518632
1802	14	189	26.3337088	50.1205642	2026-07-06 20:42:03.959983
1803	14	189	26.3336386	50.1206522	2026-07-06 20:42:05.450847
1804	14	189	26.3333487	50.1209484	2026-07-06 20:42:09.175443
1805	14	189	26.3332503	50.1210109	2026-07-06 20:42:10.451313
1806	14	189	26.3328417	50.1211493	2026-07-06 20:42:14.191446
1807	14	189	26.3327321	50.1211734	2026-07-06 20:42:15.470438
1808	14	189	26.3323162	50.1212888	2026-07-06 20:42:18.944387
1809	14	189	26.3322123	50.1213269	2026-07-06 20:42:20.472904
1810	14	189	26.3318056	50.1215065	2026-07-06 20:42:24.05288
1811	14	189	26.331715	50.1215525	2026-07-06 20:42:25.485834
1812	14	189	26.3313566	50.1217621	2026-07-06 20:42:28.947172
1813	14	189	26.3312666	50.1218217	2026-07-06 20:42:30.471199
1814	14	189	26.3309802	50.1221173	2026-07-06 20:42:33.998704
1815	14	189	26.3309147	50.122207	2026-07-06 20:42:35.511771
1816	14	189	26.3307399	50.1225592	2026-07-06 20:42:38.938156
1817	14	189	26.3307014	50.122648	2026-07-06 20:42:40.630433
1818	14	189	26.3305642	50.12296	2026-07-06 20:42:44.055341
1819	14	189	26.3305313	50.123018	2026-07-06 20:42:45.469822
1820	14	189	26.3304073	50.1231622	2026-07-06 20:42:49.02019
1821	14	189	26.3303803	50.1231765	2026-07-06 20:42:50.627929
1822	14	189	26.3302672	50.1232423	2026-07-06 20:42:54.045166
1823	14	189	26.3302454	50.1232509	2026-07-06 20:42:55.450632
1824	14	189	26.3301614	50.1232992	2026-07-06 20:42:59.131349
1825	14	189	26.3301299	50.1233116	2026-07-06 20:43:00.454082
1826	14	189	26.3299959	50.1233672	2026-07-06 20:43:04.017271
1827	14	189	26.3299495	50.1233807	2026-07-06 20:43:05.422083
1828	14	189	26.3296823	50.1235274	2026-07-06 20:43:09.339051
1829	14	189	26.3296027	50.123577	2026-07-06 20:43:10.693576
1830	14	189	26.3293693	50.1238994	2026-07-06 20:43:14.215205
1831	14	189	26.3293429	50.12401	2026-07-06 20:43:15.737466
1832	14	189	26.3293192	50.1244647	2026-07-06 20:43:19.583699
1833	14	189	26.3293325	50.1245762	2026-07-06 20:43:20.712943
1834	14	189	26.3294087	50.1250073	2026-07-06 20:43:24.183691
1835	14	189	26.3294245	50.1251154	2026-07-06 20:43:25.741127
1838	14	189	26.329543	50.126168	2026-07-06 20:43:34.224436
1843	14	189	26.3300758	50.1267946	2026-07-06 20:43:45.630147
1844	14	189	26.3305706	50.1266968	2026-07-06 20:43:49.137174
1846	14	189	26.3312726	50.1265072	2026-07-06 20:43:54.148488
1847	14	189	26.3314311	50.1264576	2026-07-06 20:43:55.658999
1851	14	189	26.3329156	50.1258664	2026-07-06 20:44:05.6636
1857	14	189	26.3348306	50.1249955	2026-07-06 20:44:20.645396
1860	14	189	26.3359329	50.1245044	2026-07-06 20:44:29.223407
1861	14	189	26.3360481	50.1244543	2026-07-06 20:44:30.659645
1867	14	189	26.3364097	50.1242757	2026-07-06 20:44:55.692613
1868	14	189	26.3364097	50.1242757	2026-07-06 20:45:00.631297
1870	14	189	26.3364314	50.1242665	2026-07-06 20:45:07.176067
1872	14	189	26.3367287	50.1241546	2026-07-06 20:45:12.185643
1873	14	189	26.3370305	50.124024	2026-07-06 20:45:15.657663
1875	14	189	26.3376289	50.1237401	2026-07-06 20:45:20.666623
1876	14	189	26.3379034	50.1236274	2026-07-06 20:45:22.20222
1879	14	189	26.3390164	50.1231145	2026-07-06 20:45:30.689702
1880	14	189	26.339319	50.1229957	2026-07-06 20:45:32.250112
1886	14	189	26.341676	50.1219592	2026-07-06 20:45:47.142252
1889	14	189	26.3429431	50.1213982	2026-07-06 20:45:55.662744
1890	14	189	26.3432497	50.1212552	2026-07-06 20:45:57.240168
1892	14	189	26.3439742	50.1209289	2026-07-06 20:46:02.092909
1895	14	189	26.3449245	50.1206757	2026-07-06 20:46:10.641807
1902	14	189	26.3464412	50.1225656	2026-07-06 20:46:27.133405
1906	14	189	26.3475551	50.1241814	2026-07-06 20:46:37.616171
1908	14	189	26.3479675	50.1251735	2026-07-06 20:46:42.228661
1909	14	189	26.3481968	50.125796	2026-07-06 20:46:45.685199
1910	14	189	26.3483422	50.1262228	2026-07-06 20:46:47.726773
1911	14	189	26.348564	50.1268684	2026-07-06 20:46:51.503411
1912	14	189	26.3487156	50.1273126	2026-07-06 20:46:52.399182
1913	14	189	26.3489315	50.1279929	2026-07-06 20:46:55.714538
1915	14	189	26.3492944	50.12913	2026-07-06 20:47:00.716527
1916	14	189	26.3494349	50.1295894	2026-07-06 20:47:02.191539
1917	14	189	26.3496631	50.1302674	2026-07-06 20:47:05.650628
1918	14	189	26.3498253	50.1307078	2026-07-06 20:47:07.294749
1920	14	189	26.3502563	50.1317485	2026-07-06 20:47:12.334508
1922	14	189	26.350749	50.1327527	2026-07-06 20:47:16.922989
1925	14	189	26.3515974	50.1342288	2026-07-06 20:47:25.518769
1926	14	189	26.3518212	50.134585	2026-07-06 20:47:27.010931
1927	14	189	26.3521616	50.1350976	2026-07-06 20:47:30.613588
1930	14	189	26.3529735	50.1362178	2026-07-06 20:47:37.438734
1931	14	189	26.3533203	50.1366826	2026-07-06 20:47:40.536514
1935	14	189	26.354489	50.138144	2026-07-06 20:47:50.476752
1937	14	189	26.3545689	50.1390095	2026-07-06 20:47:55.538407
1938	14	189	26.3543818	50.1392601	2026-07-06 20:47:57.020602
1940	14	189	26.3537551	50.1395348	2026-07-06 20:48:01.973401
1950	14	189	26.3534311	50.1371389	2026-07-06 20:48:27.344417
1951	14	189	26.353807	50.1367592	2026-07-06 20:48:30.652715
1953	14	189	26.3544271	50.1361145	2026-07-06 20:48:35.786177
1954	14	189	26.3546804	50.1358595	2026-07-06 20:48:37.151433
1956	14	189	26.3553462	50.1351801	2026-07-06 20:48:42.181609
1957	14	189	26.3557632	50.1347697	2026-07-06 20:48:45.64602
1958	14	189	26.3560661	50.1345158	2026-07-06 20:48:47.313995
1960	14	189	26.3568554	50.1339094	2026-07-06 20:48:52.142147
1962	14	189	26.3575718	50.1332446	2026-07-06 20:48:57.183261
1965	14	189	26.3586568	50.1321815	2026-07-06 20:49:05.696132
1967	14	189	26.3593262	50.1315232	2026-07-06 20:49:10.725353
1968	14	189	26.3595869	50.1312615	2026-07-06 20:49:12.287741
1970	14	189	26.3602427	50.130611	2026-07-06 20:49:17.441748
1972	14	189	26.3609066	50.1299859	2026-07-06 20:49:22.191114
1977	14	189	26.3627213	50.1285864	2026-07-06 20:49:35.807792
1980	14	189	26.3638156	50.1279407	2026-07-06 20:49:42.312739
1981	14	189	26.3643039	50.1276634	2026-07-06 20:49:45.673619
1982	14	189	26.364627	50.127484	2026-07-06 20:49:47.184656
1984	14	189	26.3654569	50.1270675	2026-07-06 20:49:52.224463
1988	14	189	26.3671736	50.126411	2026-07-06 20:50:02.185647
1991	14	189	26.368571	50.1260367	2026-07-06 20:50:10.7734
1993	14	189	26.3694277	50.125779	2026-07-06 20:50:15.743562
1994	14	189	26.3697619	50.1256833	2026-07-06 20:50:17.184289
1995	14	189	26.3702539	50.1255387	2026-07-06 20:50:20.644437
1996	14	189	26.3705743	50.125452	2026-07-06 20:50:22.222518
1997	14	189	26.3710583	50.1253087	2026-07-06 20:50:25.693257
1998	14	189	26.3713705	50.1252175	2026-07-06 20:50:27.179304
1836	14	189	26.3294852	50.1255978	2026-07-06 20:43:29.261965
1837	14	189	26.3295034	50.1257163	2026-07-06 20:43:30.878
1839	14	189	26.3295562	50.1262819	2026-07-06 20:43:35.850319
1840	14	189	26.3296119	50.1266765	2026-07-06 20:43:39.110852
1841	14	189	26.3296421	50.1267467	2026-07-06 20:43:40.662063
1842	14	189	26.3299697	50.126818	2026-07-06 20:43:44.199588
1849	14	189	26.3321975	50.1261771	2026-07-06 20:44:00.633184
1850	14	189	26.3327803	50.1259294	2026-07-06 20:44:04.101863
1852	14	189	26.3334503	50.1256194	2026-07-06 20:44:09.179033
1854	14	189	26.3340895	50.1253368	2026-07-06 20:44:14.150936
1855	14	189	26.3342127	50.1252817	2026-07-06 20:44:15.62678
1858	14	189	26.3353209	50.1247778	2026-07-06 20:44:24.148031
1859	14	189	26.3354405	50.1247241	2026-07-06 20:44:25.661349
1862	14	189	26.3363482	50.1243094	2026-07-06 20:44:34.220102
1863	14	189	26.3363741	50.124295	2026-07-06 20:44:35.645124
1864	14	189	26.3364113	50.1242766	2026-07-06 20:44:40.66798
1865	14	189	26.3364097	50.1242757	2026-07-06 20:44:45.632275
1866	14	189	26.3364097	50.1242757	2026-07-06 20:44:50.65901
1869	14	189	26.3364097	50.1242757	2026-07-06 20:45:05.68861
1871	14	189	26.3365695	50.1242083	2026-07-06 20:45:11.270803
1874	14	189	26.337264	50.1239164	2026-07-06 20:45:17.22242
1877	14	189	26.3383187	50.1234366	2026-07-06 20:45:26.040276
1878	14	189	26.3385894	50.1233101	2026-07-06 20:45:27.149249
1882	14	189	26.3400533	50.1226896	2026-07-06 20:45:37.1782
1883	14	189	26.3405301	50.1224759	2026-07-06 20:45:40.700936
1884	14	189	26.3408702	50.1223193	2026-07-06 20:45:42.234261
1885	14	189	26.3413578	50.1220976	2026-07-06 20:45:45.664133
1887	14	189	26.3421509	50.1217452	2026-07-06 20:45:50.659406
1888	14	189	26.3424732	50.1215977	2026-07-06 20:45:52.160774
1891	14	189	26.3436824	50.1210574	2026-07-06 20:46:00.641473
1893	14	189	26.3443832	50.1207457	2026-07-06 20:46:05.644852
1896	14	189	26.345071	50.1208094	2026-07-06 20:46:12.200816
1897	14	189	26.3452773	50.1210953	2026-07-06 20:46:15.689125
1898	14	189	26.3454263	50.1213131	2026-07-06 20:46:17.189323
1900	14	189	26.3459003	50.1219172	2026-07-06 20:46:22.20688
1901	14	189	26.3462148	50.1222911	2026-07-06 20:46:25.757645
1903	14	189	26.3467944	50.1229899	2026-07-06 20:46:30.711815
1904	14	189	26.3470304	50.1232971	2026-07-06 20:46:32.234805
1905	14	189	26.3473569	50.1237988	2026-07-06 20:46:35.745564
1907	14	189	26.3478081	50.1247736	2026-07-06 20:46:40.715455
1914	14	189	26.3490779	50.1284481	2026-07-06 20:46:57.168224
1919	14	189	26.3500759	50.1313454	2026-07-06 20:47:10.847641
1921	14	189	26.3505486	50.1323567	2026-07-06 20:47:15.458161
1923	14	189	26.3510614	50.1333199	2026-07-06 20:47:20.470324
1928	14	189	26.352397	50.1354187	2026-07-06 20:47:31.963565
1929	14	189	26.3527425	50.135898	2026-07-06 20:47:35.570868
1932	14	189	26.3535525	50.1369809	2026-07-06 20:47:42.29682
1933	14	189	26.3539122	50.1374221	2026-07-06 20:47:45.470666
1934	14	189	26.3541477	50.1377015	2026-07-06 20:47:47.104316
1936	14	189	26.3546122	50.1384907	2026-07-06 20:47:52.058293
1939	14	189	26.3540208	50.1394777	2026-07-06 20:48:00.687963
1941	14	189	26.3533389	50.1395356	2026-07-06 20:48:05.526364
1942	14	189	26.3530694	50.1394669	2026-07-06 20:48:07.015084
1944	14	189	26.3525058	50.1390288	2026-07-06 20:48:12.501403
1946	14	189	26.3524095	50.1386186	2026-07-06 20:48:17.93194
1947	14	189	26.352664	50.137978	2026-07-06 20:48:20.714751
1948	14	189	26.3528604	50.1377482	2026-07-06 20:48:22.410057
1949	14	189	26.353199	50.1373871	2026-07-06 20:48:25.738527
1952	14	189	26.3540487	50.1365041	2026-07-06 20:48:32.33119
1955	14	189	26.3550788	50.1354585	2026-07-06 20:48:40.665549
1959	14	189	26.3565434	50.1341558	2026-07-06 20:48:50.699177
1961	14	189	26.3572929	50.1335132	2026-07-06 20:48:55.649497
1963	14	189	26.3579757	50.1328464	2026-07-06 20:49:00.64776
1966	14	189	26.358924	50.1319209	2026-07-06 20:49:07.153915
1969	14	189	26.3599825	50.1308665	2026-07-06 20:49:15.629543
1971	14	189	26.3606404	50.1302246	2026-07-06 20:49:20.674486
1973	14	189	26.3613105	50.1296351	2026-07-06 20:49:25.685673
1974	14	189	26.3615926	50.1294076	2026-07-06 20:49:27.173951
1975	14	189	26.362007	50.129097	2026-07-06 20:49:30.6972
1976	14	189	26.3622902	50.1288885	2026-07-06 20:49:32.263324
1979	14	189	26.3634958	50.1281217	2026-07-06 20:49:40.70587
1983	14	189	26.3651243	50.1272311	2026-07-06 20:49:50.717258
1985	14	189	26.3659622	50.1268268	2026-07-06 20:49:55.877715
1986	14	189	26.3663001	50.1266702	2026-07-06 20:49:57.201218
1987	14	189	26.36682	50.1264918	2026-07-06 20:50:00.736406
1989	14	189	26.3677019	50.1262869	2026-07-06 20:50:05.670779
1990	14	189	26.3680505	50.1261848	2026-07-06 20:50:07.182058
1992	14	189	26.368914	50.1259303	2026-07-06 20:50:12.222941
1845	14	189	26.3307007	50.1266674	2026-07-06 20:43:50.663007
1848	14	189	26.3320496	50.1262369	2026-07-06 20:43:59.12031
1853	14	189	26.3335815	50.1255635	2026-07-06 20:44:10.698618
1856	14	189	26.3347069	50.1250531	2026-07-06 20:44:19.183417
1881	14	189	26.3397405	50.1228172	2026-07-06 20:45:35.714609
1894	14	189	26.3446377	50.1206413	2026-07-06 20:46:07.221245
1899	14	189	26.3456985	50.1216697	2026-07-06 20:46:20.720239
1924	14	189	26.3512728	50.1336923	2026-07-06 20:47:22.140832
1943	14	189	26.3526931	50.1392453	2026-07-06 20:48:10.480371
1945	14	189	26.3524612	50.1383439	2026-07-06 20:48:17.858223
1964	14	189	26.3582516	50.1325811	2026-07-06 20:49:02.138985
1978	14	189	26.3630176	50.1283948	2026-07-06 20:49:37.194441
1999	14	189	26.3718383	50.1250756	2026-07-06 20:50:30.852511
2000	14	189	26.3721339	50.1249818	2026-07-06 20:50:32.178179
2001	14	189	26.3725375	50.1248499	2026-07-06 20:50:36.023695
2002	14	189	26.372748	50.1247874	2026-07-06 20:50:37.107946
2003	14	189	26.3729617	50.124808	2026-07-06 20:50:40.676956
2004	14	189	26.373048	50.1249404	2026-07-06 20:50:42.129899
2005	14	189	26.3730397	50.125205	2026-07-06 20:50:45.760972
2006	14	189	26.3730189	50.1254357	2026-07-06 20:50:47.03876
2007	14	189	26.3729802	50.1258298	2026-07-06 20:50:50.765166
2008	14	189	26.3729315	50.1261121	2026-07-06 20:50:52.124207
2009	14	189	26.3728522	50.1265263	2026-07-06 20:50:55.663153
2010	14	189	26.3728255	50.1268005	2026-07-06 20:50:57.102896
2011	14	189	26.3727647	50.1271459	2026-07-06 20:51:00.625988
2012	14	189	26.3727386	50.1273123	2026-07-06 20:51:02.167174
2013	14	189	26.3727827	50.1274127	2026-07-06 20:51:05.655237
2014	14	189	26.3728408	50.1273839	2026-07-06 20:51:07.243434
2015	14	189	26.3728827	50.1272087	2026-07-06 20:51:10.633174
2016	14	189	26.372976	50.1267891	2026-07-06 20:51:15.673525
2017	14	189	26.3730768	50.1261965	2026-07-06 20:51:20.725373
2018	14	189	26.3731497	50.1255274	2026-07-06 20:51:25.667661
2019	14	190	26.3742327	50.1226794	2026-07-06 20:53:17.333706
2020	14	190	26.3744955	50.1225964	2026-07-06 20:53:22.213685
2021	14	190	26.3748776	50.1224815	2026-07-06 20:53:27.248319
2022	14	190	26.3752152	50.1223902	2026-07-06 20:53:32.101779
2023	14	191	26.3764829	50.1225406	2026-07-06 20:54:06.004949
2024	14	191	26.3765226	50.1228534	2026-07-06 20:54:10.322197
2025	14	191	26.3766063	50.1228948	2026-07-06 20:54:16.151031
2026	14	191	26.3766517	50.1227373	2026-07-06 20:54:21.299957
2027	14	191	26.3765941	50.1224168	2026-07-06 20:54:26.276917
2028	14	191	26.3766361	50.1221586	2026-07-06 20:54:31.132452
2029	14	191	26.3768672	50.1220825	2026-07-06 20:54:36.13806
2030	14	191	26.3771265	50.12201	2026-07-06 20:54:41.136443
2031	14	191	26.3773746	50.1219338	2026-07-06 20:54:46.158038
2032	14	191	26.3776093	50.1218706	2026-07-06 20:54:51.255324
2033	14	191	26.3778224	50.1217967	2026-07-06 20:54:56.256637
2034	14	191	26.3782135	50.1217411	2026-07-06 20:55:06.172785
2035	14	191	26.3784047	50.1216779	2026-07-06 20:55:11.180904
2036	7	198	26.39832973042919	50.144826023497856	2026-07-07 09:59:26.24164
2037	7	198	26.39832973042919	50.144826023497856	2026-07-07 10:01:00.947961
2038	7	198	26.398280063493118	50.14483101368386	2026-07-07 10:01:12.955656
2039	13	199	26.3785219	50.1213242	2026-07-08 18:36:24.782628
2040	13	199	26.3785308	50.1213049	2026-07-08 18:36:29.936994
2041	13	199	26.378583	50.1212911	2026-07-08 18:36:30.258836
2042	13	199	26.378583	50.1212911	2026-07-08 18:36:34.989509
2043	13	199	26.3787806	50.1212425	2026-07-08 18:36:35.082379
2044	13	199	26.3787806	50.1212425	2026-07-08 18:36:39.864388
2045	7	201	26.3784858	50.1213398	2026-07-08 23:08:38.114077
2046	7	201	26.3784858	50.1213398	2026-07-08 23:08:39.750763
2047	13	211	26.3977549	50.1453501	2026-07-09 16:00:23.753795
2048	13	212	26.3799537	50.1203587	2026-07-09 21:34:21.95197
2049	13	212	26.3799636	50.120376	2026-07-09 21:34:27.064898
2050	13	212	26.3799753	50.1204368	2026-07-09 21:34:28.949373
2051	13	212	26.3799919	50.1204958	2026-07-09 21:34:31.91156
2052	13	212	26.3800196	50.1206441	2026-07-09 21:34:33.994797
2053	13	212	26.3800464	50.1207715	2026-07-09 21:34:36.782981
2054	13	212	26.3800801	50.120975	2026-07-09 21:34:38.854435
2055	13	212	26.3800751	50.1210719	2026-07-09 21:34:41.779306
2056	13	212	26.3799766	50.1211416	2026-07-09 21:34:43.883365
2057	13	212	26.3798662	50.1211738	2026-07-09 21:34:46.760714
2058	13	212	26.3796863	50.1212215	2026-07-09 21:34:48.672453
2059	13	212	26.3795514	50.1212533	2026-07-09 21:34:51.63708
2060	13	212	26.3793548	50.1213109	2026-07-09 21:34:53.831925
2061	13	212	26.3792193	50.1213606	2026-07-09 21:34:56.571625
2062	13	212	26.379009	50.121399	2026-07-09 21:34:58.887981
2063	13	212	26.3788638	50.1214303	2026-07-09 21:35:01.827476
2064	13	212	26.3788209	50.1214417	2026-07-09 21:35:06.544081
2065	13	212	26.3786435	50.1214926	2026-07-09 21:35:07.836603
2066	13	212	26.3785232	50.1215131	2026-07-09 21:35:12.790653
2067	13	212	26.3785438	50.1216674	2026-07-09 21:37:31.788804
2068	13	212	26.3785892	50.1219162	2026-07-09 21:37:38.199497
2069	13	212	26.378621	50.1221578	2026-07-09 21:37:41.888428
2070	13	212	26.3786679	50.1223426	2026-07-09 21:37:47.461239
2071	13	212	26.3786619	50.1224327	2026-07-09 21:38:02.142843
2072	13	212	26.3785321	50.1224297	2026-07-09 21:38:02.457423
2073	13	212	26.3784253	50.1224504	2026-07-09 21:38:06.462807
2074	13	212	26.3783991	50.1224608	2026-07-09 21:38:06.738929
2075	13	212	26.3783485	50.1224989	2026-07-09 21:38:11.492371
2076	13	212	26.3783253	50.1225093	2026-07-09 21:38:16.457511
2077	13	212	26.3783015	50.1224968	2026-07-09 21:38:17.796314
2078	13	212	26.3781755	50.1225185	2026-07-09 21:38:21.6172
2079	13	212	26.3780246	50.1225681	2026-07-09 21:38:22.868007
2080	13	212	26.3777401	50.1226809	2026-07-09 21:38:26.636616
2081	13	212	26.3775329	50.1227567	2026-07-09 21:38:27.891246
2082	13	212	26.3771903	50.1228776	2026-07-09 21:38:31.671636
2083	13	212	26.376931	50.1229734	2026-07-09 21:38:32.909741
2084	13	212	26.3765205	50.1231226	2026-07-09 21:38:37.080216
2085	13	212	26.3762369	50.1232228	2026-07-09 21:38:37.812831
2086	13	212	26.3757911	50.123342	2026-07-09 21:38:41.614157
2087	13	212	26.375496	50.1234319	2026-07-09 21:38:42.897347
2088	13	212	26.3750704	50.1235582	2026-07-09 21:38:46.786813
2089	13	212	26.3747973	50.1236388	2026-07-09 21:38:47.89554
2090	13	212	26.3744112	50.1237445	2026-07-09 21:38:51.638259
2091	13	212	26.3741667	50.1238107	2026-07-09 21:38:52.878053
2092	13	212	26.3738469	50.1239056	2026-07-09 21:38:56.631087
2093	13	212	26.3736793	50.1239679	2026-07-09 21:38:57.873166
2094	13	212	26.3734979	50.1241099	2026-07-09 21:39:01.674852
2095	13	212	26.3734245	50.1242478	2026-07-09 21:39:02.956864
2096	13	212	26.3734506	50.1244141	2026-07-09 21:39:06.62941
2097	13	212	26.3736069	50.1244637	2026-07-09 21:39:07.836442
2098	13	212	26.3738408	50.12444	2026-07-09 21:39:11.675604
2100	13	212	26.3743318	50.1243011	2026-07-09 21:39:16.612531
2101	13	212	26.3745624	50.1242353	2026-07-09 21:39:17.898864
2102	13	212	26.3749403	50.1241447	2026-07-09 21:39:21.687846
2103	13	212	26.3752085	50.1240708	2026-07-09 21:39:22.766444
2104	13	212	26.3756229	50.1239494	2026-07-09 21:39:26.573518
2105	13	212	26.375909	50.1238678	2026-07-09 21:39:27.751393
2107	13	212	26.3771479	50.1235106	2026-07-09 21:39:36.470674
2109	13	212	26.3779717	50.12325	2026-07-09 21:39:41.484777
2110	13	212	26.3783309	50.1231267	2026-07-09 21:39:42.797171
2111	13	212	26.378906	50.1229537	2026-07-09 21:39:46.461722
2112	13	212	26.3793036	50.122837	2026-07-09 21:39:47.744424
2113	13	212	26.3798912	50.122672	2026-07-09 21:39:51.491101
2119	13	212	26.3828336	50.1217605	2026-07-09 21:40:06.490016
2122	13	212	26.3841877	50.1213603	2026-07-09 21:40:12.797022
2125	13	212	26.3857472	50.1208443	2026-07-09 21:40:21.486232
2128	13	212	26.3872808	50.1203764	2026-07-09 21:40:27.799366
2131	13	212	26.3891079	50.1198326	2026-07-09 21:40:36.449416
2133	13	212	26.3902445	50.1194963	2026-07-09 21:40:41.498503
2134	13	212	26.3907017	50.1193606	2026-07-09 21:40:42.763967
2135	13	212	26.3913787	50.1191687	2026-07-09 21:40:46.468513
2137	13	212	26.3924675	50.1188362	2026-07-09 21:40:51.424498
2141	13	212	26.394573	50.1182181	2026-07-09 21:41:01.638237
2145	13	212	26.3967021	50.1175819	2026-07-09 21:41:11.617197
2147	13	212	26.3977188	50.1172603	2026-07-09 21:41:16.619527
2149	13	212	26.3986926	50.1168969	2026-07-09 21:41:21.599652
2150	13	212	26.3990563	50.116752	2026-07-09 21:41:22.70362
2151	13	212	26.3995889	50.1165022	2026-07-09 21:41:26.440033
2152	13	212	26.3999241	50.1163318	2026-07-09 21:41:27.66956
2153	13	212	26.400415	50.1161045	2026-07-09 21:41:31.449138
2155	13	212	26.4011959	50.1157602	2026-07-09 21:41:36.451586
2156	13	212	26.4014731	50.1156255	2026-07-09 21:41:37.691782
2157	13	212	26.4018026	50.1154585	2026-07-09 21:41:41.451633
2158	13	212	26.4019524	50.1154057	2026-07-09 21:41:42.746965
2161	13	212	26.4019188	50.115931	2026-07-09 21:41:51.492436
2163	13	212	26.4016434	50.1164215	2026-07-09 21:41:56.496307
2165	13	212	26.4014093	50.1168356	2026-07-09 21:42:01.585165
2166	13	212	26.4013399	50.1169454	2026-07-09 21:42:02.803978
2167	13	212	26.4012433	50.1169943	2026-07-09 21:42:06.43159
2099	13	212	26.3740195	50.1243928	2026-07-09 21:39:13.038055
2106	13	212	26.3766762	50.1236573	2026-07-09 21:39:32.947184
2108	13	212	26.377469	50.123413	2026-07-09 21:39:37.74511
2114	13	212	26.3802894	50.1225732	2026-07-09 21:39:52.775004
2115	13	212	26.3808736	50.1223958	2026-07-09 21:39:56.495175
2116	13	212	26.3812616	50.1222676	2026-07-09 21:39:57.733109
2117	13	212	26.3818455	50.1220628	2026-07-09 21:40:01.473616
2118	13	212	26.382244	50.1219372	2026-07-09 21:40:02.739127
2120	13	212	26.3832286	50.1216474	2026-07-09 21:40:07.746267
2121	13	212	26.3838097	50.1214786	2026-07-09 21:40:11.460434
2123	13	212	26.3847583	50.1211708	2026-07-09 21:40:16.462195
2124	13	212	26.385147	50.1210399	2026-07-09 21:40:18.242895
2126	13	212	26.386164	50.1207098	2026-07-09 21:40:22.784173
2127	13	212	26.3868266	50.1205079	2026-07-09 21:40:26.478101
2129	13	212	26.387968	50.1201684	2026-07-09 21:40:31.470789
2130	13	212	26.3884231	50.120031	2026-07-09 21:40:32.756941
2132	13	212	26.3895648	50.1196962	2026-07-09 21:40:37.701853
2136	13	212	26.3918171	50.1190387	2026-07-09 21:40:47.757633
2138	13	212	26.3928883	50.1187123	2026-07-09 21:40:52.676966
2139	13	212	26.3935247	50.11853	2026-07-09 21:40:56.395003
2140	13	212	26.3939421	50.1184019	2026-07-09 21:40:57.682599
2142	13	212	26.3950042	50.1180845	2026-07-09 21:41:02.87842
2143	13	212	26.3956492	50.1178936	2026-07-09 21:41:06.595449
2144	13	212	26.3960739	50.1177695	2026-07-09 21:41:07.877001
2146	13	212	26.397113	50.117458	2026-07-09 21:41:13.083201
2148	13	212	26.3981125	50.1171151	2026-07-09 21:41:17.852882
2154	13	212	26.4007329	50.1159717	2026-07-09 21:41:32.712025
2159	13	212	26.4020929	50.1155144	2026-07-09 21:41:46.480157
2160	13	212	26.4020759	50.1156804	2026-07-09 21:41:47.676189
2162	13	212	26.4018084	50.1161266	2026-07-09 21:41:52.716049
2164	13	212	26.4015445	50.1165979	2026-07-09 21:41:57.72002
2168	13	212	26.4012048	50.1170086	2026-07-09 21:42:07.695149
2169	13	212	26.4011903	50.1170212	2026-07-09 21:42:11.464903
2170	13	212	26.4011175	50.1170904	2026-07-09 21:42:15.970284
2171	13	212	26.4011175	50.1170904	2026-07-09 21:42:16.458435
2172	13	212	26.40098	50.1171906	2026-07-09 21:42:20.65613
2173	13	212	26.40098	50.1171906	2026-07-09 21:42:21.426878
2174	13	213	26.399322	50.1181489	2026-07-09 22:38:28.887223
2175	13	213	26.3996479	50.1181862	2026-07-09 22:38:34.00402
2176	13	213	26.3993997	50.1180914	2026-07-09 22:38:38.903438
2177	13	213	26.3989494	50.117932	2026-07-09 22:38:43.848754
2178	13	213	26.3989474	50.1179312	2026-07-09 22:38:44.944746
2179	13	213	26.3988079	50.1177981	2026-07-09 22:38:48.918732
2180	13	213	26.3987776	50.1177818	2026-07-09 22:38:49.971901
2181	13	213	26.3986981	50.1177636	2026-07-09 22:38:53.851587
2182	13	213	26.3986808	50.1177333	2026-07-09 22:38:54.901827
2183	13	213	26.3987926	50.1175313	2026-07-09 22:38:58.962627
2184	13	213	26.398835	50.1174467	2026-07-09 22:38:59.915458
2185	13	213	26.3990445	50.1170271	2026-07-09 22:39:03.981604
2186	13	213	26.3990908	50.1169354	2026-07-09 22:39:04.952335
2187	13	213	26.3993852	50.1166882	2026-07-09 22:39:08.899419
2188	13	213	26.3994809	50.1166358	2026-07-09 22:39:09.925691
2189	13	213	26.3999206	50.1164147	2026-07-09 22:39:13.849625
2190	13	213	26.4000166	50.1163717	2026-07-09 22:39:14.938987
2191	13	213	26.4002415	50.1162466	2026-07-09 22:39:18.869553
2192	13	213	26.4002982	50.1162308	2026-07-09 22:39:20.06792
2193	13	213	26.4005826	50.1160881	2026-07-09 22:39:23.973911
2194	13	213	26.4006635	50.1160392	2026-07-09 22:39:24.943923
2195	13	213	26.4010793	50.1157922	2026-07-09 22:39:28.930671
2196	13	213	26.401199	50.1157269	2026-07-09 22:39:29.966372
2197	13	213	26.4017247	50.1154508	2026-07-09 22:39:33.975818
2198	13	213	26.4018584	50.1153834	2026-07-09 22:39:34.957312
2199	13	213	26.4024417	50.1150831	2026-07-09 22:39:38.851156
2200	13	213	26.4025943	50.1150014	2026-07-09 22:39:39.976711
2201	13	213	26.403242	50.1146678	2026-07-09 22:39:44.113179
2202	13	213	26.4034135	50.1145781	2026-07-09 22:39:44.917826
2203	13	213	26.404082	50.1142429	2026-07-09 22:39:48.91938
2204	13	213	26.4042384	50.114161	2026-07-09 22:39:49.960928
2205	13	213	26.4048587	50.1138351	2026-07-09 22:39:53.945067
2206	13	213	26.4050246	50.1137465	2026-07-09 22:39:54.944309
2207	13	213	26.4057043	50.1134044	2026-07-09 22:39:58.910348
2208	13	213	26.4058757	50.1133106	2026-07-09 22:39:59.9405
2209	13	213	26.4065769	50.1129514	2026-07-09 22:40:03.976183
2210	13	213	26.4067549	50.1128648	2026-07-09 22:40:04.958719
2211	13	213	26.4074278	50.1125032	2026-07-09 22:40:08.906256
2212	13	213	26.407591	50.1124115	2026-07-09 22:40:09.943909
2213	13	213	26.4082226	50.112058	2026-07-09 22:40:13.86161
2214	13	213	26.4083779	50.1119699	2026-07-09 22:40:14.959023
2215	13	213	26.4090062	50.111631	2026-07-09 22:40:18.841895
2216	13	213	26.4091591	50.1115513	2026-07-09 22:40:19.936842
2217	13	213	26.4097463	50.1112434	2026-07-09 22:40:23.900324
2218	13	213	26.4098772	50.1111678	2026-07-09 22:40:24.976304
2219	13	213	26.4103571	50.1109075	2026-07-09 22:40:28.899759
2220	13	213	26.4104491	50.1108627	2026-07-09 22:40:29.916134
2221	13	213	26.4105993	50.1106991	2026-07-09 22:40:33.8592
2222	13	213	26.4105898	50.1106417	2026-07-09 22:40:34.948454
2223	13	213	26.4103688	50.1106169	2026-07-09 22:40:38.972659
2224	13	213	26.4102872	50.1106413	2026-07-09 22:40:39.951797
2225	13	213	26.409904	50.1107829	2026-07-09 22:40:43.976987
2226	13	213	26.409795	50.1108344	2026-07-09 22:40:45.023996
2227	13	213	26.4093579	50.1110643	2026-07-09 22:40:48.99896
2228	13	213	26.4092474	50.1111214	2026-07-09 22:40:49.916968
2229	13	213	26.4088214	50.1113493	2026-07-09 22:40:53.903143
2230	13	213	26.4087138	50.1114011	2026-07-09 22:40:54.981539
2231	13	213	26.4082618	50.1116337	2026-07-09 22:40:59.015863
2232	13	213	26.4081453	50.1116969	2026-07-09 22:40:59.974516
2233	13	213	26.4076399	50.1119611	2026-07-09 22:41:03.81902
2234	13	213	26.4075085	50.11203	2026-07-09 22:41:04.93179
2235	13	213	26.4069797	50.1123071	2026-07-09 22:41:08.951073
2236	13	213	26.4068493	50.1123718	2026-07-09 22:41:09.936457
2237	13	213	26.4063496	50.1126301	2026-07-09 22:41:13.922979
2238	13	213	26.4062269	50.1126898	2026-07-09 22:41:14.944072
2239	13	213	26.405736	50.1129607	2026-07-09 22:41:19.100627
2240	13	213	26.4056124	50.1130279	2026-07-09 22:41:19.940305
2241	13	213	26.4051104	50.1133016	2026-07-09 22:41:24.183942
2242	13	213	26.4049857	50.1133738	2026-07-09 22:41:24.758826
2243	13	213	26.4044485	50.1136661	2026-07-09 22:41:28.727784
2244	13	213	26.4043112	50.1137354	2026-07-09 22:41:29.771156
2245	13	213	26.4037788	50.1140078	2026-07-09 22:41:33.708671
2246	13	213	26.403648	50.1140737	2026-07-09 22:41:34.868143
2247	13	213	26.4032411	50.1142924	2026-07-09 22:41:38.730315
2248	13	213	26.4031474	50.1143406	2026-07-09 22:41:39.734648
2249	13	213	26.4027189	50.1145546	2026-07-09 22:41:43.674335
2250	13	213	26.402595	50.1146211	2026-07-09 22:41:44.742583
2251	13	213	26.4020672	50.1148976	2026-07-09 22:41:48.689578
2252	13	213	26.4019308	50.1149668	2026-07-09 22:41:49.796146
2253	13	213	26.4014272	50.1152644	2026-07-09 22:41:53.694276
2254	13	213	26.4013012	50.1153382	2026-07-09 22:41:54.784883
2255	13	213	26.4007491	50.1156515	2026-07-09 22:41:58.688664
2256	13	213	26.4005984	50.115728	2026-07-09 22:41:59.781671
2257	13	213	26.4000156	50.116024	2026-07-09 22:42:03.725584
2258	13	213	26.3998589	50.1161036	2026-07-09 22:42:04.835644
2259	13	213	26.3992275	50.1164154	2026-07-09 22:42:08.731351
2260	13	213	26.3990655	50.1164863	2026-07-09 22:42:09.76623
2261	13	213	26.3983973	50.1167716	2026-07-09 22:42:13.711738
2262	13	213	26.3875645	50.1200206	2026-07-09 22:43:13.724353
2263	13	213	26.3873987	50.1200686	2026-07-09 22:43:14.783819
2264	13	213	26.3867192	50.1202454	2026-07-09 22:43:18.72634
2265	13	213	26.3865497	50.1202933	2026-07-09 22:43:19.733167
2266	13	213	26.3858887	50.120487	2026-07-09 22:43:23.920507
2267	13	213	26.385725	50.1205377	2026-07-09 22:43:24.964592
2268	13	213	26.3850811	50.120707	2026-07-09 22:43:28.938147
2269	13	213	26.384926	50.1207435	2026-07-09 22:43:29.950292
2270	13	213	26.3842616	50.120879	2026-07-09 22:43:33.868189
2271	13	213	26.3840919	50.120924	2026-07-09 22:43:34.946206
2272	13	213	26.3834489	50.1210964	2026-07-09 22:43:38.898508
2273	13	213	26.3832941	50.1211374	2026-07-09 22:43:39.956276
2274	13	213	26.3826865	50.1213304	2026-07-09 22:43:43.860896
2275	13	213	26.3825353	50.1213762	2026-07-09 22:43:44.950078
2276	13	213	26.3819539	50.1215355	2026-07-09 22:43:49.018661
2277	13	213	26.3818158	50.1215764	2026-07-09 22:43:49.923259
2278	13	213	26.3813416	50.1217001	2026-07-09 22:43:54.012315
2279	13	213	26.3812351	50.1217377	2026-07-09 22:43:54.903454
2280	13	216	26.3796388	50.1190519	2026-07-10 17:45:53.203206
2281	13	216	26.3796387	50.1190518	2026-07-10 17:45:58.274575
2282	13	216	26.379667	50.1190475	2026-07-10 17:46:01.432466
2283	13	216	26.3796946	50.1190521	2026-07-10 17:46:03.124699
2284	13	216	26.3797978	50.1192794	2026-07-10 17:46:06.329091
2285	13	216	26.3798163	50.1193692	2026-07-10 17:46:08.132581
2286	13	216	26.379889	50.1197869	2026-07-10 17:46:11.446683
2287	13	216	26.3799124	50.1199041	2026-07-10 17:46:13.158987
2288	13	216	26.3799598	50.1202198	2026-07-10 17:46:16.452604
2289	13	216	26.3799642	50.1202662	2026-07-10 17:46:18.098542
2290	13	216	26.3800054	50.1205154	2026-07-10 17:46:21.355128
2291	13	216	26.3800192	50.1206076	2026-07-10 17:46:23.177582
2292	13	216	26.3800845	50.1209705	2026-07-10 17:46:26.433701
2293	13	216	26.3800897	50.1210416	2026-07-10 17:46:28.136239
2294	13	216	26.3800015	50.1211669	2026-07-10 17:46:31.555957
2295	13	216	26.3799362	50.1211873	2026-07-10 17:46:33.142101
2296	13	216	26.3796104	50.1212743	2026-07-10 17:46:36.482228
2297	13	216	26.3795236	50.1212939	2026-07-10 17:46:38.131126
2298	13	216	26.3791846	50.1213822	2026-07-10 17:46:41.557222
2299	13	216	26.3791032	50.1214037	2026-07-10 17:46:43.074705
2300	13	216	26.3788058	50.1214897	2026-07-10 17:46:46.469711
2301	13	216	26.3787417	50.1215069	2026-07-10 17:46:48.321336
2302	13	216	26.3785564	50.1215448	2026-07-10 17:46:51.582927
2303	13	216	26.3785295	50.1215488	2026-07-10 17:46:53.304828
2304	13	216	26.3784609	50.121573	2026-07-10 17:46:57.410034
2305	13	216	26.3785276	50.1215936	2026-07-10 17:48:57.087222
2306	13	216	26.3785151	50.1215776	2026-07-10 17:49:02.025767
2307	13	216	26.378499	50.1216173	2026-07-10 17:49:07.342261
2308	13	216	26.378532	50.1217714	2026-07-10 17:49:10.589681
2309	13	216	26.3785416	50.1219386	2026-07-10 17:49:12.046469
2310	13	216	26.3785548	50.1222192	2026-07-10 17:49:15.383093
2311	13	216	26.3785637	50.1222956	2026-07-10 17:49:18.140854
2312	13	216	26.3786323	50.1224604	2026-07-10 17:49:20.59419
2313	13	216	26.3786386	50.1224723	2026-07-10 17:49:22.012819
2314	13	216	26.3785378	50.12252	2026-07-10 17:49:26.622473
2315	13	216	26.3785378	50.12252	2026-07-10 17:49:28.541815
2316	13	216	26.3783609	50.1224989	2026-07-10 17:49:31.564956
2317	13	216	26.3783609	50.1224989	2026-07-10 17:49:32.084097
2318	13	216	26.3782134	50.1225529	2026-07-10 17:49:36.64659
2319	13	216	26.3782134	50.1225529	2026-07-10 17:49:37.07486
2320	13	216	26.3778229	50.122686	2026-07-10 17:49:41.615969
2321	13	216	26.3778229	50.122686	2026-07-10 17:49:42.089238
2322	13	216	26.3773025	50.1228818	2026-07-10 17:49:46.445796
2323	13	216	26.3773025	50.1228818	2026-07-10 17:49:47.012554
2324	13	216	26.376727	50.1230648	2026-07-10 17:49:51.430038
2325	13	216	26.376727	50.1230648	2026-07-10 17:49:52.017021
2326	13	216	26.3761236	50.1232498	2026-07-10 17:49:56.45239
2327	13	216	26.3761236	50.1232498	2026-07-10 17:49:56.991562
2328	13	216	26.3754435	50.1234698	2026-07-10 17:50:01.335105
2329	13	216	26.3754435	50.1234698	2026-07-10 17:50:01.999124
2330	13	216	26.3747952	50.1236425	2026-07-10 17:50:06.454973
2331	13	216	26.3747952	50.1236425	2026-07-10 17:50:07.0178
2332	13	216	26.3741756	50.123815	2026-07-10 17:50:11.324064
2333	13	216	26.3741756	50.123815	2026-07-10 17:50:12.062644
2334	13	216	26.3736505	50.1239214	2026-07-10 17:50:16.40322
2335	13	216	26.3736505	50.1239214	2026-07-10 17:50:17.079317
2336	13	216	26.3735266	50.1236253	2026-07-10 17:50:21.46144
2337	13	216	26.3735266	50.1236253	2026-07-10 17:50:22.025432
2338	13	216	26.3736023	50.1231302	2026-07-10 17:50:26.573647
2339	13	216	26.3736023	50.1231302	2026-07-10 17:50:27.016072
2340	13	216	26.3737327	50.1224626	2026-07-10 17:50:31.345651
2341	13	216	26.3737327	50.1224626	2026-07-10 17:50:31.953949
2342	13	216	26.3738819	50.1217193	2026-07-10 17:50:36.385704
2343	13	216	26.3738819	50.1217193	2026-07-10 17:50:37.070103
2344	13	216	26.3740364	50.121118	2026-07-10 17:50:41.394991
2345	13	216	26.3740364	50.121118	2026-07-10 17:50:41.967796
2346	13	216	26.3741029	50.1208883	2026-07-10 17:50:46.501368
2347	13	216	26.3741029	50.1208883	2026-07-10 17:50:47.085565
2348	13	216	26.3741056	50.1208709	2026-07-10 17:50:52.027667
2349	13	216	26.3741056	50.1208709	2026-07-10 17:50:57.095148
2350	13	216	26.3741056	50.1208709	2026-07-10 17:51:02.05211
2351	13	216	26.3741056	50.1208709	2026-07-10 17:51:06.991894
2352	13	216	26.3741056	50.1208709	2026-07-10 17:51:12.097504
2354	13	216	26.3741056	50.1208709	2026-07-10 17:51:22.095727
2357	13	216	26.3741082	50.1206807	2026-07-10 17:51:32.111682
2358	13	216	26.3741248	50.1203003	2026-07-10 17:51:35.488459
2359	13	216	26.3741441	50.1201773	2026-07-10 17:51:36.997443
2360	13	216	26.3742125	50.1196531	2026-07-10 17:51:40.41296
2361	13	216	26.3742281	50.1195067	2026-07-10 17:51:42.229865
2362	13	216	26.3743023	50.1188604	2026-07-10 17:51:45.51051
2366	13	216	26.3746009	50.1168576	2026-07-10 17:51:56.979213
2367	13	216	26.3747183	50.1161779	2026-07-10 17:52:00.416794
2369	13	216	26.374883	50.1153672	2026-07-10 17:52:05.805315
2370	13	216	26.374913	50.1152074	2026-07-10 17:52:07.026781
2372	13	216	26.375064	50.114404	2026-07-10 17:52:12.483629
2374	13	216	26.3752017	50.1136128	2026-07-10 17:52:17.038389
2375	13	216	26.3752968	50.1129308	2026-07-10 17:52:20.474251
2376	13	216	26.375322	50.1127572	2026-07-10 17:52:22.082952
2378	13	216	26.3754433	50.1118145	2026-07-10 17:52:27.096938
2380	13	216	26.3755251	50.1107876	2026-07-10 17:52:31.993343
2381	13	216	26.3755811	50.1099331	2026-07-10 17:52:35.337165
2382	13	216	26.3755866	50.109726	2026-07-10 17:52:37.012706
2383	13	216	26.3756097	50.1089205	2026-07-10 17:52:40.857845
2385	13	216	26.3755988	50.1080063	2026-07-10 17:52:45.391109
2386	13	216	26.3755899	50.1078315	2026-07-10 17:52:47.024964
2387	13	216	26.375529	50.1070878	2026-07-10 17:52:50.353348
2388	13	216	26.3755102	50.1068991	2026-07-10 17:52:52.287722
2389	13	216	26.3754535	50.1061462	2026-07-10 17:52:55.959712
2390	13	216	26.3754454	50.1059615	2026-07-10 17:52:57.041257
2392	13	216	26.3755556	50.1053264	2026-07-10 17:53:02.133017
2393	13	216	26.3757691	50.1050016	2026-07-10 17:53:05.379644
2395	13	216	26.3760353	50.1046388	2026-07-10 17:53:10.5056
2396	13	216	26.3760684	50.1045536	2026-07-10 17:53:12.094929
2398	13	216	26.3760219	50.1040174	2026-07-10 17:53:17.120101
2399	13	216	26.3757356	50.1036987	2026-07-10 17:53:20.691262
2400	13	216	26.3756458	50.1036506	2026-07-10 17:53:22.217492
2402	13	216	26.3751125	50.1037154	2026-07-10 17:53:27.844502
2404	13	216	26.3746923	50.103522	2026-07-10 17:53:32.053502
2407	13	216	26.3741126	50.102324	2026-07-10 17:53:40.636904
2408	13	216	26.3740597	50.1021578	2026-07-10 17:53:42.196213
2409	13	216	26.3738658	50.1014649	2026-07-10 17:53:45.527956
2410	13	216	26.3738092	50.1012828	2026-07-10 17:53:47.066802
2412	13	216	26.373537	50.1003834	2026-07-10 17:53:52.053668
2414	13	216	26.3730087	50.0986944	2026-07-10 17:54:00.680454
2415	13	216	26.3729484	50.0985045	2026-07-10 17:54:02.068071
2416	13	216	26.3727017	50.0977419	2026-07-10 17:54:06.139254
2417	13	216	26.37264	50.0975526	2026-07-10 17:54:07.113523
2418	13	216	26.3723951	50.0968225	2026-07-10 17:54:10.509356
2421	13	216	26.3720752	50.0957901	2026-07-10 17:54:19.137974
2424	13	216	26.3716868	50.0945015	2026-07-10 17:54:25.346825
2425	13	216	26.371647	50.0943783	2026-07-10 17:54:27.212063
2426	13	216	26.371481	50.0939005	2026-07-10 17:54:30.35789
2427	13	216	26.3714397	50.0937901	2026-07-10 17:54:32.192857
2428	13	216	26.3714264	50.0934462	2026-07-10 17:54:35.344765
2430	13	216	26.3718952	50.0930887	2026-07-10 17:54:42.536117
2432	13	216	26.3724504	50.0926932	2026-07-10 17:54:47.1542
2435	13	216	26.3736788	50.0919026	2026-07-10 17:54:55.575858
2440	13	216	26.3753903	50.0907812	2026-07-10 17:55:06.999041
2441	13	216	26.376005	50.0903936	2026-07-10 17:55:10.382008
2442	13	216	26.3761612	50.0902907	2026-07-10 17:55:12.111218
2444	13	216	26.3769531	50.0897823	2026-07-10 17:55:17.030965
2445	13	216	26.3775942	50.0893544	2026-07-10 17:55:20.573598
2447	13	216	26.3784589	50.0887753	2026-07-10 17:55:25.532944
2449	13	216	26.3793877	50.0881689	2026-07-10 17:55:30.368983
2450	13	216	26.3795695	50.0880507	2026-07-10 17:55:32.022426
2451	13	216	26.3802802	50.0875747	2026-07-10 17:55:35.452142
2452	13	216	26.3804499	50.0874575	2026-07-10 17:55:37.048375
2453	13	216	26.3811038	50.0870039	2026-07-10 17:55:40.393279
2454	13	216	26.3812521	50.0868894	2026-07-10 17:55:42.062944
2456	13	216	26.3818627	50.0864056	2026-07-10 17:55:47.02996
2457	13	216	26.3823158	50.0860884	2026-07-10 17:55:50.410126
2458	13	216	26.3824412	50.0860073	2026-07-10 17:55:52.019308
2459	13	216	26.3829442	50.0856522	2026-07-10 17:55:55.494278
2461	13	216	26.3837025	50.0851726	2026-07-10 17:56:00.42923
2462	13	216	26.3838644	50.085072	2026-07-10 17:56:02.044989
2463	13	216	26.3845268	50.084637	2026-07-10 17:56:05.61221
2464	13	216	26.3847081	50.0845263	2026-07-10 17:56:07.106405
2467	13	216	26.3862213	50.0835394	2026-07-10 17:56:15.925812
2469	13	216	26.3869766	50.0830351	2026-07-10 17:56:20.521703
2471	13	216	26.3874986	50.0827086	2026-07-10 17:56:26.137468
2472	13	216	26.3875995	50.0826558	2026-07-10 17:56:27.066014
2473	13	216	26.3880148	50.0824195	2026-07-10 17:56:30.509239
2474	13	216	26.3881333	50.0823527	2026-07-10 17:56:31.986559
2475	13	216	26.3885744	50.082055	2026-07-10 17:56:35.368199
2476	13	216	26.388681	50.0819707	2026-07-10 17:56:36.973553
2478	13	216	26.3892962	50.0815758	2026-07-10 17:56:42.016651
2479	13	216	26.3898213	50.0814165	2026-07-10 17:56:45.450972
2480	13	216	26.3899488	50.0814655	2026-07-10 17:56:47.00849
2486	13	216	26.3904609	50.0831723	2026-07-10 17:57:02.027889
2491	13	216	26.3891514	50.0837765	2026-07-10 17:57:15.349851
2494	13	216	26.3887437	50.083113	2026-07-10 17:57:22.032881
2496	13	216	26.388443	50.0824038	2026-07-10 17:57:27.046563
2498	13	216	26.3880727	50.0815583	2026-07-10 17:57:32.066398
2499	13	216	26.3877152	50.080784	2026-07-10 17:57:35.411878
2500	13	216	26.3876221	50.0805868	2026-07-10 17:57:37.024877
2502	13	216	26.3871212	50.0796125	2026-07-10 17:57:42.024121
2503	13	216	26.3866938	50.0788811	2026-07-10 17:57:45.347397
2505	13	216	26.3860793	50.0779591	2026-07-10 17:57:50.374236
2506	13	216	26.385959	50.0777818	2026-07-10 17:57:52.024502
2508	13	216	26.3853676	50.0769012	2026-07-10 17:57:57.022477
2510	13	216	26.3847728	50.0760342	2026-07-10 17:58:02.004611
2513	13	216	26.3837406	50.0744932	2026-07-10 17:58:10.411834
2514	13	216	26.3836409	50.0743353	2026-07-10 17:58:11.990994
2518	13	216	26.3831045	50.0733067	2026-07-10 17:58:21.991596
2521	13	216	26.3834324	50.0730446	2026-07-10 17:58:30.900392
2523	13	216	26.3837123	50.0727878	2026-07-10 17:58:35.44139
2527	13	216	26.3842127	50.072389	2026-07-10 17:58:45.361933
2529	13	216	26.3845103	50.0721485	2026-07-10 17:58:50.384933
2353	13	216	26.3741056	50.1208709	2026-07-10 17:51:16.971722
2355	13	216	26.3741056	50.1208709	2026-07-10 17:51:27.09937
2356	13	216	26.3741034	50.1207574	2026-07-10 17:51:30.506459
2363	13	216	26.3743233	50.1186869	2026-07-10 17:51:47.078782
2364	13	216	26.374419	50.1179326	2026-07-10 17:51:50.48966
2365	13	216	26.3745694	50.1170309	2026-07-10 17:51:55.567949
2368	13	216	26.3747533	50.1160131	2026-07-10 17:52:01.994565
2371	13	216	26.3750344	50.1145687	2026-07-10 17:52:10.365239
2373	13	216	26.3751819	50.1137706	2026-07-10 17:52:15.454307
2377	13	216	26.3754266	50.1120092	2026-07-10 17:52:25.5043
2379	13	216	26.3755128	50.1109969	2026-07-10 17:52:30.44223
2384	13	216	26.3756112	50.1087261	2026-07-10 17:52:41.994334
2391	13	216	26.3755128	50.1054219	2026-07-10 17:53:00.37998
2394	13	216	26.3758328	50.1049317	2026-07-10 17:53:07.066155
2397	13	216	26.3760613	50.1041309	2026-07-10 17:53:15.387228
2401	13	216	26.3752058	50.1036841	2026-07-10 17:53:27.394523
2403	13	216	26.3747735	50.1035948	2026-07-10 17:53:30.75557
2405	13	216	26.3743925	50.1030818	2026-07-10 17:53:35.469453
2406	13	216	26.3743267	50.102942	2026-07-10 17:53:37.057508
2411	13	216	26.3735906	50.1005594	2026-07-10 17:53:50.901087
2413	13	216	26.3733067	50.0996679	2026-07-10 17:53:55.648184
2419	13	216	26.3723332	50.0966407	2026-07-10 17:54:12.091137
2420	13	216	26.37212	50.0959515	2026-07-10 17:54:15.493194
2422	13	216	26.3718825	50.0951778	2026-07-10 17:54:20.411431
2423	13	216	26.3718311	50.0950355	2026-07-10 17:54:22.223333
2429	13	216	26.3714864	50.0933868	2026-07-10 17:54:37.05141
2431	13	216	26.3723311	50.0927766	2026-07-10 17:54:45.45672
2433	13	216	26.3729584	50.0923542	2026-07-10 17:54:50.482296
2434	13	216	26.3731004	50.0922606	2026-07-10 17:54:52.311361
2436	13	216	26.3738226	50.0918077	2026-07-10 17:54:57.086114
2437	13	216	26.3744324	50.0914095	2026-07-10 17:55:00.73809
2438	13	216	26.3745918	50.0913034	2026-07-10 17:55:02.716889
2439	13	216	26.3752309	50.0908887	2026-07-10 17:55:05.815525
2443	13	216	26.3767951	50.089888	2026-07-10 17:55:15.381496
2446	13	216	26.3777595	50.0892448	2026-07-10 17:55:22.026478
2448	13	216	26.3786422	50.088652	2026-07-10 17:55:27.041341
2455	13	216	26.3817595	50.0864906	2026-07-10 17:55:45.407414
2460	13	216	26.3830849	50.0855607	2026-07-10 17:55:57.034745
2465	13	216	26.3853892	50.0840849	2026-07-10 17:56:10.922943
2466	13	216	26.3855539	50.0839738	2026-07-10 17:56:12.017727
2468	13	216	26.3863793	50.0834332	2026-07-10 17:56:17.058676
2470	13	216	26.3870945	50.0829572	2026-07-10 17:56:22.21182
2477	13	216	26.3891723	50.0816477	2026-07-10 17:56:40.438414
2481	13	216	26.39037	50.0817961	2026-07-10 17:56:50.344229
2482	13	216	26.3904298	50.0819039	2026-07-10 17:56:52.004743
2483	13	216	26.3905559	50.0824038	2026-07-10 17:56:55.453023
2484	13	216	26.3905652	50.0825325	2026-07-10 17:56:57.021549
2485	13	216	26.3904968	50.0830505	2026-07-10 17:57:00.44706
2487	13	216	26.3902083	50.0836305	2026-07-10 17:57:05.4009
2488	13	216	26.3901251	50.0837273	2026-07-10 17:57:07.025511
2489	13	216	26.3896878	50.0839394	2026-07-10 17:57:10.405511
2490	13	216	26.389571	50.0839498	2026-07-10 17:57:12.012079
2492	13	216	26.3890598	50.0836979	2026-07-10 17:57:17.235519
2493	13	216	26.3887985	50.0832422	2026-07-10 17:57:20.472498
2495	13	216	26.3885055	50.0825573	2026-07-10 17:57:25.532835
2497	13	216	26.3881566	50.0817379	2026-07-10 17:57:30.398162
2501	13	216	26.3872228	50.0798073	2026-07-10 17:57:40.42665
2504	13	216	26.3865734	50.0786953	2026-07-10 17:57:47.031854
2507	13	216	26.3854893	50.0770743	2026-07-10 17:57:55.42421
2509	13	216	26.3848946	50.0762076	2026-07-10 17:58:00.393742
2511	13	216	26.3842954	50.0753444	2026-07-10 17:58:05.436445
2512	13	216	26.3841754	50.0751738	2026-07-10 17:58:06.995128
2515	13	216	26.3832909	50.0737709	2026-07-10 17:58:15.383112
2516	13	216	26.383227	50.0736446	2026-07-10 17:58:17.00554
2517	13	216	26.3830924	50.0733346	2026-07-10 17:58:20.483501
2519	13	216	26.3832027	50.0731972	2026-07-10 17:58:25.360249
2520	13	216	26.383236	50.0731709	2026-07-10 17:58:27.014075
2522	13	216	26.3834836	50.072999	2026-07-10 17:58:32.073752
2524	13	216	26.383771	50.0727398	2026-07-10 17:58:37.31422
2525	13	216	26.3839442	50.0726075	2026-07-10 17:58:40.438187
2526	13	216	26.3839855	50.0725747	2026-07-10 17:58:41.989792
2528	13	216	26.3842829	50.0723309	2026-07-10 17:58:47.014796
2532	13	216	26.3846834	50.072095	2026-07-10 17:58:56.99817
2533	13	216	26.3847574	50.072252	2026-07-10 17:59:00.465119
2535	13	216	26.384907	50.0724967	2026-07-10 17:59:05.386687
2536	13	216	26.3849442	50.0725512	2026-07-10 17:59:07.281071
2539	13	216	26.3853797	50.0732156	2026-07-10 17:59:15.397754
2540	13	216	26.3854401	50.073292	2026-07-10 17:59:16.990716
2541	13	216	26.3856469	50.0735854	2026-07-10 17:59:20.414855
2543	13	216	26.3857875	50.0738631	2026-07-10 17:59:25.479191
2544	13	216	26.385785	50.0738992	2026-07-10 17:59:27.038533
2546	13	216	26.3856058	50.0741259	2026-07-10 17:59:32.051223
2547	13	216	26.3853137	50.0743665	2026-07-10 17:59:35.527449
2548	13	216	26.3852501	50.0744282	2026-07-10 17:59:37.011611
2549	13	216	26.3849974	50.0746702	2026-07-10 17:59:40.388997
2551	13	216	26.384732	50.0749222	2026-07-10 17:59:45.348403
2552	13	216	26.3847064	50.0749493	2026-07-10 17:59:47.339702
2553	13	216	26.3848532	50.074913	2026-07-10 17:59:51.530765
2554	13	216	26.3848532	50.074913	2026-07-10 17:59:52.082922
2555	13	216	26.3851793	50.0745774	2026-07-10 17:59:56.401558
2556	13	216	26.3851793	50.0745774	2026-07-10 17:59:57.039633
2557	13	216	26.3856061	50.0741997	2026-07-10 18:00:01.377304
2558	13	216	26.3856061	50.0741997	2026-07-10 18:00:02.031442
2559	13	216	26.3860115	50.0738811	2026-07-10 18:00:06.409299
2562	13	216	26.3863326	50.0736241	2026-07-10 18:00:12.040983
2564	13	216	26.3864861	50.0735819	2026-07-10 18:00:16.985873
2565	13	216	26.3867044	50.0738442	2026-07-10 18:00:21.2973
2567	13	216	26.3869099	50.0741015	2026-07-10 18:00:26.386136
2568	13	216	26.3869099	50.0741015	2026-07-10 18:00:27.043368
2570	13	216	26.3869599	50.0742245	2026-07-10 18:00:32.088908
2572	13	216	26.3869304	50.0743491	2026-07-10 18:00:37.395117
2530	13	216	26.3845437	50.0721203	2026-07-10 17:58:52.029798
2531	13	216	26.3846563	50.0720673	2026-07-10 17:58:55.39118
2534	13	216	26.3847814	50.0722869	2026-07-10 17:59:02.035565
2537	13	216	26.385122	50.0728156	2026-07-10 17:59:10.349715
2538	13	216	26.3851725	50.07289	2026-07-10 17:59:12.041707
2542	13	216	26.3856916	50.0736601	2026-07-10 17:59:22.030655
2545	13	216	26.3856551	50.074075	2026-07-10 17:59:30.346031
2550	13	216	26.3849382	50.0747333	2026-07-10 17:59:41.992333
2560	13	216	26.3860115	50.0738811	2026-07-10 18:00:07.046912
2561	13	216	26.3863326	50.0736241	2026-07-10 18:00:11.466519
2563	13	216	26.3864861	50.0735819	2026-07-10 18:00:16.450759
2566	13	216	26.3867044	50.0738442	2026-07-10 18:00:21.948061
2569	13	216	26.3869599	50.0742245	2026-07-10 18:00:31.34156
2571	13	216	26.3869304	50.0743491	2026-07-10 18:00:37.164899
2573	13	216	26.3866406	50.0746307	2026-07-10 18:00:42.038464
2574	13	216	26.3862013	50.0750024	2026-07-10 18:00:46.586209
2575	13	216	26.3862013	50.0750024	2026-07-10 18:00:47.031866
2576	13	216	26.3858741	50.0752824	2026-07-10 18:00:51.872913
2577	13	216	26.3858741	50.0752824	2026-07-10 18:00:52.046342
2578	13	216	26.3859053	50.0755384	2026-07-10 18:00:56.444323
2579	13	216	26.3859053	50.0755384	2026-07-10 18:00:57.013245
2580	13	216	26.3860976	50.0757849	2026-07-10 18:01:01.532414
2581	13	216	26.3860976	50.0757849	2026-07-10 18:01:02.000026
2582	13	216	26.3862525	50.0759942	2026-07-10 18:01:06.361056
2583	13	216	26.3862525	50.0759942	2026-07-10 18:01:07.08498
2584	13	216	26.3863871	50.0759523	2026-07-10 18:01:11.347906
2585	13	216	26.3863871	50.0759523	2026-07-10 18:01:12.068991
2586	13	216	26.3865057	50.0758184	2026-07-10 18:01:16.30238
2587	13	216	26.3865057	50.0758184	2026-07-10 18:01:16.97697
2588	13	216	26.3866818	50.0756503	2026-07-10 18:01:21.283161
2589	13	216	26.3866818	50.0756503	2026-07-10 18:01:22.186913
2590	13	216	26.3868722	50.0754832	2026-07-10 18:01:26.303096
2591	13	216	26.3868722	50.0754832	2026-07-10 18:01:27.001133
2592	13	216	26.3870378	50.0753401	2026-07-10 18:01:31.453464
2593	13	216	26.3870378	50.0753401	2026-07-10 18:01:31.991795
2594	13	216	26.3872111	50.07517	2026-07-10 18:01:36.363591
2595	13	216	26.3872111	50.07517	2026-07-10 18:01:37.001775
2596	13	216	26.3873712	50.0751331	2026-07-10 18:01:41.446973
2597	13	216	26.3873712	50.0751331	2026-07-10 18:01:42.031825
2598	13	216	26.3874102	50.0751453	2026-07-10 18:01:47.059282
2599	13	216	26.3874102	50.0751453	2026-07-10 18:01:52.935034
2600	13	216	26.3874102	50.0751453	2026-07-10 18:01:56.97152
2601	13	216	26.3874649	50.0751596	2026-07-10 18:02:00.522741
2602	13	216	26.3874901	50.0751619	2026-07-10 18:02:02.001785
2603	13	216	26.3875292	50.0751611	2026-07-10 18:02:06.93864
2604	13	216	26.3875289	50.0751614	2026-07-10 18:02:12.064203
2605	13	216	26.3875289	50.0751614	2026-07-10 18:02:16.998259
2606	13	216	26.3875513	50.0751992	2026-07-10 18:02:21.488934
2607	13	216	26.3875513	50.0751992	2026-07-10 18:02:21.978455
2608	13	216	26.3875659	50.0753002	2026-07-10 18:02:26.446338
2609	13	216	26.3875659	50.0753002	2026-07-10 18:02:26.984498
2610	13	216	26.3875571	50.0753079	2026-07-10 18:02:31.958545
2611	13	216	26.3875962	50.0753326	2026-07-10 18:02:36.992913
2612	13	216	26.3876602	50.0753207	2026-07-10 18:02:39.38973
2613	13	216	26.3876703	50.0753116	2026-07-10 18:02:41.952553
2614	13	217	26.3876862	50.0753289	2026-07-10 19:12:05.155575
2615	13	217	26.3876862	50.0753289	2026-07-10 19:12:10.170131
2616	13	217	26.3876862	50.0753289	2026-07-10 19:12:15.122168
2617	13	217	26.3876787	50.0753364	2026-07-10 19:12:20.173665
2618	13	217	26.3876585	50.0753439	2026-07-10 19:12:25.140073
2619	13	217	26.3877025	50.0754073	2026-07-10 19:12:30.056395
2620	13	217	26.3877242	50.0754508	2026-07-10 19:12:30.33098
2621	13	217	26.3878182	50.0756027	2026-07-10 19:12:35.04368
2622	13	217	26.3878369	50.0756274	2026-07-10 19:12:35.272963
2623	13	217	26.387912	50.0756534	2026-07-10 19:12:40.110417
2624	13	217	26.3879468	50.0756359	2026-07-10 19:12:40.32902
2625	13	217	26.3880086	50.0756136	2026-07-10 19:12:45.164903
2626	13	217	26.3880459	50.075632	2026-07-10 19:12:49.303081
2627	13	217	26.3880459	50.075632	2026-07-10 19:12:50.0176
2628	13	217	26.3881424	50.0758007	2026-07-10 19:12:54.343542
2629	13	217	26.3881424	50.0758007	2026-07-10 19:12:55.069347
2630	13	217	26.3880646	50.0759212	2026-07-10 19:12:59.290527
2631	13	217	26.3880646	50.0759212	2026-07-10 19:13:00.028401
2632	13	217	26.3878248	50.0761381	2026-07-10 19:13:04.323367
2633	13	217	26.3878248	50.0761381	2026-07-10 19:13:05.072028
2634	13	217	26.3874519	50.0764703	2026-07-10 19:13:09.319893
2635	13	217	26.3874519	50.0764703	2026-07-10 19:13:10.173618
2636	13	217	26.3870032	50.0768678	2026-07-10 19:13:14.245873
2637	13	217	26.3870032	50.0768678	2026-07-10 19:13:15.011648
2638	13	217	26.3865344	50.0772725	2026-07-10 19:13:19.442233
2639	13	217	26.3865344	50.0772725	2026-07-10 19:13:20.05863
2640	13	217	26.3860788	50.0774186	2026-07-10 19:13:24.275524
2641	13	217	26.3860788	50.0774186	2026-07-10 19:13:25.070204
2642	13	217	26.3845781	50.0750524	2026-07-10 19:13:50.063615
2643	13	217	26.3850324	50.0747175	2026-07-10 19:13:54.792598
2644	13	217	26.3850324	50.0747175	2026-07-10 19:13:55.106459
2645	13	217	26.3855531	50.0742652	2026-07-10 19:13:59.32638
2646	13	217	26.3855531	50.0742652	2026-07-10 19:14:00.086175
2647	13	217	26.386042	50.0738477	2026-07-10 19:14:04.449436
2648	13	217	26.386042	50.0738477	2026-07-10 19:14:05.122631
2649	13	217	26.3863776	50.0735657	2026-07-10 19:14:09.307222
2650	13	217	26.3863776	50.0735657	2026-07-10 19:14:10.150608
2651	13	217	26.3865828	50.0734089	2026-07-10 19:14:14.51476
2652	13	217	26.3865828	50.0734089	2026-07-10 19:14:15.121883
2653	13	217	26.38696	50.0730912	2026-07-10 19:14:19.332044
2654	13	217	26.38696	50.0730912	2026-07-10 19:14:20.08416
2655	13	217	26.3873997	50.0727443	2026-07-10 19:14:24.258945
2656	13	217	26.3873997	50.0727443	2026-07-10 19:14:25.062547
2657	13	217	26.3878014	50.0724474	2026-07-10 19:14:29.333257
2658	13	217	26.3878014	50.0724474	2026-07-10 19:14:30.064912
2659	13	217	26.3879926	50.0723053	2026-07-10 19:14:34.298268
2660	13	217	26.3879926	50.0723053	2026-07-10 19:14:35.087419
2661	13	217	26.3882913	50.0720868	2026-07-10 19:14:39.344807
2662	13	217	26.3882913	50.0720868	2026-07-10 19:14:40.107171
2663	13	217	26.3887152	50.0716931	2026-07-10 19:14:44.307151
2664	13	217	26.3887152	50.0716931	2026-07-10 19:14:45.123297
2665	13	217	26.3891778	50.0713243	2026-07-10 19:14:49.268532
2666	13	217	26.3891778	50.0713243	2026-07-10 19:14:50.070373
2667	13	217	26.389453	50.0712719	2026-07-10 19:14:54.362535
2669	13	217	26.3896905	50.0716117	2026-07-10 19:14:59.399761
2670	13	217	26.3896905	50.0716117	2026-07-10 19:15:00.060458
2671	13	217	26.3899016	50.0719417	2026-07-10 19:15:04.333436
2672	13	217	26.3899016	50.0719417	2026-07-10 19:15:05.090139
2673	13	217	26.3899808	50.0720464	2026-07-10 19:15:09.29158
2674	13	217	26.3899808	50.0720464	2026-07-10 19:15:10.277114
2675	13	217	26.3901461	50.0723007	2026-07-10 19:15:14.413785
2676	13	217	26.3901461	50.0723007	2026-07-10 19:15:15.074916
2677	13	217	26.3903812	50.07264	2026-07-10 19:15:19.259738
2678	13	217	26.3903812	50.07264	2026-07-10 19:15:20.024294
2679	13	217	26.3906407	50.0730029	2026-07-10 19:15:24.439417
2680	13	217	26.3906407	50.0730029	2026-07-10 19:15:25.060279
2681	13	217	26.3908764	50.0733402	2026-07-10 19:15:29.282469
2684	13	217	26.3909388	50.0735479	2026-07-10 19:15:35.043129
2686	13	217	26.3907175	50.0737653	2026-07-10 19:15:40.140672
2688	13	217	26.3903208	50.0741323	2026-07-10 19:15:45.05823
2689	13	217	26.3897885	50.074611	2026-07-10 19:15:49.353303
2691	13	217	26.3891538	50.0751443	2026-07-10 19:15:54.285063
2692	13	217	26.3891538	50.0751443	2026-07-10 19:15:55.153701
2694	13	217	26.3884442	50.0757449	2026-07-10 19:16:00.102712
2668	13	217	26.389453	50.0712719	2026-07-10 19:14:54.997312
2682	13	217	26.3908764	50.0733402	2026-07-10 19:15:30.26487
2683	13	217	26.3909388	50.0735479	2026-07-10 19:15:34.237108
2685	13	217	26.3907175	50.0737653	2026-07-10 19:15:39.39961
2687	13	217	26.3903208	50.0741323	2026-07-10 19:15:44.328751
2690	13	217	26.3897885	50.074611	2026-07-10 19:15:50.137175
2693	13	217	26.3884442	50.0757449	2026-07-10 19:15:59.486651
2695	13	217	26.3784234	50.0842894	2026-07-10 19:17:04.33883
2696	13	217	26.3784234	50.0842894	2026-07-10 19:17:05.086116
2697	13	217	26.3776808	50.0849236	2026-07-10 19:17:09.378595
2698	13	217	26.3776808	50.0849236	2026-07-10 19:17:10.106506
2699	13	217	26.3769324	50.0855583	2026-07-10 19:17:14.376548
2700	13	217	26.3769324	50.0855583	2026-07-10 19:17:15.116281
2701	13	217	26.3762737	50.0861352	2026-07-10 19:17:19.526444
2702	13	217	26.3762737	50.0861352	2026-07-10 19:17:20.354552
2703	13	217	26.3757367	50.0866236	2026-07-10 19:17:24.789034
2704	13	217	26.3757367	50.0866236	2026-07-10 19:17:25.091983
2705	13	217	26.3751926	50.0870638	2026-07-10 19:17:29.296752
2706	13	217	26.3751926	50.0870638	2026-07-10 19:17:30.110608
2707	13	217	26.3747647	50.0874193	2026-07-10 19:17:34.308065
2708	13	217	26.3747647	50.0874193	2026-07-10 19:17:35.151857
2709	13	217	26.3743948	50.0877006	2026-07-10 19:17:39.545023
2710	13	217	26.3743948	50.0877006	2026-07-10 19:17:40.279423
2711	13	217	26.3739352	50.0880441	2026-07-10 19:17:45.308427
2712	13	217	26.3739352	50.0880441	2026-07-10 19:17:45.495514
2713	13	217	26.3736768	50.0882495	2026-07-10 19:17:49.445762
2714	13	217	26.3736768	50.0882495	2026-07-10 19:17:50.200954
2715	13	217	26.3734093	50.0884871	2026-07-10 19:17:55.28563
2716	13	217	26.3734093	50.0884871	2026-07-10 19:17:55.723678
2717	13	217	26.3729827	50.0888927	2026-07-10 19:17:59.426621
2718	13	217	26.3698046	50.0890294	2026-07-10 19:18:49.332359
2719	13	217	26.3697506	50.0888528	2026-07-10 19:19:00.104117
2720	13	217	26.3697307	50.0888103	2026-07-10 19:19:01.42233
2721	13	217	26.3697026	50.0887363	2026-07-10 19:19:05.146903
2722	13	217	26.3696785	50.088688	2026-07-10 19:19:06.371608
2723	13	217	26.3696522	50.0886098	2026-07-10 19:19:10.181452
2724	13	217	26.3696392	50.0885672	2026-07-10 19:19:11.318558
2725	13	217	26.3695965	50.0884792	2026-07-10 19:19:15.120672
2726	13	217	26.3695655	50.0884051	2026-07-10 19:19:16.495176
2727	13	217	26.3695213	50.0883231	2026-07-10 19:19:20.049481
2728	13	217	26.3695131	50.0882948	2026-07-10 19:19:21.309627
2729	13	217	26.3694958	50.0882291	2026-07-10 19:19:25.273831
2730	13	217	26.3694841	50.0881851	2026-07-10 19:19:26.457572
2731	13	217	26.3694727	50.0881484	2026-07-10 19:19:30.071247
2732	13	217	26.3694523	50.0880758	2026-07-10 19:19:32.300948
2733	13	217	26.3694344	50.0880143	2026-07-10 19:19:35.101524
2734	13	217	26.3694148	50.0879688	2026-07-10 19:19:37.399652
2735	13	217	26.369416	50.0879434	2026-07-10 19:19:40.061766
2736	13	217	26.3693897	50.0878493	2026-07-10 19:19:43.635105
2737	13	217	26.3693821	50.0878265	2026-07-10 19:19:45.046829
2738	13	217	26.36931	50.0877951	2026-07-10 19:19:48.58233
2739	13	217	26.3692887	50.0878112	2026-07-10 19:19:50.095512
2740	13	217	26.3693031	50.0880518	2026-07-10 19:19:53.336519
2741	13	217	26.3693257	50.088143	2026-07-10 19:19:55.060224
2742	13	217	26.3719565	50.096384	2026-07-10 19:20:55.520012
2743	13	217	26.3721828	50.0970643	2026-07-10 19:20:58.346678
2744	13	217	26.3722473	50.0972408	2026-07-10 19:21:00.164421
2745	13	217	26.372502	50.0979759	2026-07-10 19:21:03.660397
2746	13	217	26.3725653	50.0981641	2026-07-10 19:21:05.249902
2747	13	217	26.3728298	50.098928	2026-07-10 19:21:08.613029
2748	13	217	26.3728993	50.0991248	2026-07-10 19:21:10.18932
2749	13	217	26.3731493	50.0999282	2026-07-10 19:21:14.002097
2750	13	217	26.3732093	50.1001515	2026-07-10 19:21:15.184398
2751	13	217	26.3734716	50.1010171	2026-07-10 19:21:19.316677
2752	13	217	26.3735373	50.1012408	2026-07-10 19:21:20.154785
2753	13	217	26.3738086	50.1021147	2026-07-10 19:21:23.345655
2754	13	217	26.3738779	50.1023323	2026-07-10 19:21:25.203332
2755	13	217	26.3741713	50.103185	2026-07-10 19:21:28.655882
2756	13	217	26.3742734	50.1033884	2026-07-10 19:21:34.018231
2757	13	217	26.3748197	50.1040527	2026-07-10 19:21:34.326076
2758	13	217	26.3749845	50.104192	2026-07-10 19:21:35.418744
2759	13	217	26.3757404	50.1045065	2026-07-10 19:21:38.686752
2760	13	217	26.3759378	50.1045424	2026-07-10 19:21:40.435635
2761	13	217	26.3766908	50.1044953	2026-07-10 19:21:43.363857
2762	13	217	26.3768756	50.1044342	2026-07-10 19:21:45.774854
2763	13	217	26.3775826	50.1042146	2026-07-10 19:21:48.355028
2764	13	217	26.3777585	50.104164	2026-07-10 19:21:50.263523
2765	13	217	26.381133	50.1040523	2026-07-10 19:22:08.594436
2766	13	217	26.3813169	50.1040624	2026-07-10 19:22:10.079973
2767	13	217	26.3820474	50.1041065	2026-07-10 19:22:13.300255
2768	13	217	26.3822341	50.1041168	2026-07-10 19:22:15.450686
2769	13	217	26.3829724	50.1041432	2026-07-10 19:22:18.488869
2770	13	217	26.383156	50.1041459	2026-07-10 19:22:20.132189
2771	13	217	26.3838917	50.104167	2026-07-10 19:22:23.589051
2772	13	217	26.3840733	50.1041708	2026-07-10 19:22:25.253401
2773	13	217	26.3847974	50.1041846	2026-07-10 19:22:28.300608
2774	13	217	26.38497	50.1041829	2026-07-10 19:22:30.074113
2775	13	217	26.3857065	50.1042032	2026-07-10 19:22:33.350614
2776	13	217	26.3858856	50.1042137	2026-07-10 19:22:35.172662
2777	13	217	26.3866356	50.1042343	2026-07-10 19:22:38.366939
2778	13	217	26.3868207	50.1042437	2026-07-10 19:22:40.059911
2779	13	217	26.3875601	50.1043044	2026-07-10 19:22:43.248333
2780	13	217	26.3877484	50.1043101	2026-07-10 19:22:45.047171
2781	13	217	26.3884943	50.1043326	2026-07-10 19:22:48.364952
2782	13	217	26.3886799	50.1043386	2026-07-10 19:22:50.074705
2783	13	217	26.3894093	50.1043587	2026-07-10 19:22:53.360008
2784	13	217	26.3895892	50.1043674	2026-07-10 19:22:55.06569
2785	13	217	26.3903061	50.1044218	2026-07-10 19:22:58.364162
2786	13	217	26.3904768	50.1044313	2026-07-10 19:23:00.007162
2787	13	217	26.3911452	50.1044168	2026-07-10 19:23:03.320083
2788	13	217	26.3914774	50.104423	2026-07-10 19:23:05.381506
2789	13	217	26.3919596	50.1044331	2026-07-10 19:23:08.27892
2790	13	217	26.3921221	50.1044496	2026-07-10 19:23:10.045405
2791	13	217	26.392745	50.1045074	2026-07-10 19:23:13.463644
2792	13	217	26.392889	50.1045179	2026-07-10 19:23:15.045591
2793	13	217	26.3934228	50.1045581	2026-07-10 19:23:18.222144
2794	13	217	26.3935389	50.1045795	2026-07-10 19:23:20.056408
2795	13	217	26.3939455	50.1046173	2026-07-10 19:23:23.393102
2796	13	217	26.3940447	50.1046229	2026-07-10 19:23:25.010238
2797	13	217	26.3944651	50.1046329	2026-07-10 19:23:28.41137
2800	13	217	26.4003179	50.1048373	2026-07-10 19:24:35.058738
2801	13	217	26.4005473	50.1048566	2026-07-10 19:24:38.332629
2802	13	217	26.4005893	50.1048657	2026-07-10 19:24:40.433468
2803	13	217	26.4006409	50.1049468	2026-07-10 19:24:43.291716
2804	13	217	26.400649	50.1049605	2026-07-10 19:24:45.082945
2798	13	217	26.3945681	50.1046316	2026-07-10 19:23:30.061381
2799	13	217	26.3949886	50.1046383	2026-07-10 19:23:33.422411
2805	13	217	26.4006402	50.1050596	2026-07-10 19:24:49.479653
2806	13	217	26.4006402	50.1050596	2026-07-10 19:24:49.989805
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, content, is_read, sent_at, status, receiver_id, sender_id, ride_id) FROM stdin;
1	hello	f	2026-05-07 10:55:24.065796	sent	2	3	\N
2	hi	f	2026-05-07 10:57:32.846473	sent	2	3	\N
3	hi	f	2026-05-07 11:20:56.341817	sent	2	3	\N
4	hi how is going	f	2026-05-07 11:21:11.806896	sent	3	2	\N
5	hello again	f	2026-05-07 11:54:15.558498	sent	2	3	\N
6	hi	f	2026-05-07 15:51:16.851555	sent	2	3	\N
7	no notification	f	2026-05-07 15:51:40.154392	sent	2	3	\N
8	11-05-2026	f	2026-05-11 08:46:27.288195	sent	3	2	\N
9	11-05-2026	f	2026-05-11 08:46:46.819156	sent	2	3	\N
10	hello	f	2026-05-14 10:09:56.032969	sent	7	6	\N
11	hello	f	2026-05-14 12:01:06.176597	sent	10	9	\N
12	hi	f	2026-05-15 13:50:14.140906	sent	7	6	\N
13	hi	f	2026-05-25 11:27:08.310473	sent	7	6	\N
14	hello	f	2026-05-25 11:29:04.938551	sent	7	6	\N
15	hi	f	2026-05-25 11:29:14.968424	sent	6	7	\N
16	when you are coming man ???	f	2026-05-25 11:29:28.331683	sent	7	6	\N
17	just 5 min	f	2026-05-25 11:29:41.146323	sent	6	7	\N
18	ok thanks	f	2026-05-25 11:29:49.576182	sent	7	6	\N
19	hi	f	2026-05-25 16:23:57.607896	sent	7	6	\N
20	مرحبا هل انت هنا	f	2026-05-29 01:37:37.934229	sent	7	6	\N
21	نعم	f	2026-05-29 01:37:51.985408	sent	6	7	\N
22	hi	f	2026-05-29 12:31:47.981496	sent	7	6	\N
23	hello	f	2026-05-29 12:32:11.918496	sent	6	7	\N
24	اهلا	f	2026-06-01 14:24:23.738546	sent	7	6	\N
25	الو	f	2026-06-01 22:44:08.614397	sent	7	6	\N
26	كيفك	f	2026-06-01 22:44:15.159213	sent	7	6	\N
27	الووو	f	2026-06-01 22:44:21.227025	sent	6	7	\N
28	تعال بسرعه	f	2026-06-01 22:44:32.294793	sent	7	6	\N
29	مرحبا الى اين تروحين ؟	f	2026-06-01 22:44:39.34116	sent	6	7	\N
30	hello	f	2026-06-04 16:32:02.330532	sent	7	6	\N
31	hi yes tell me what can I do for you?	f	2026-06-04 16:35:15.991517	sent	6	7	\N
32	when you are comming?	f	2026-06-04 16:35:24.238398	sent	7	6	\N
33	soon give me 5 min	f	2026-06-04 16:35:35.07006	sent	6	7	\N
34	ok	f	2026-06-04 16:35:41.755544	sent	7	6	\N
35	hi	f	2026-06-04 16:55:50.39843	sent	7	6	\N
36	hello	f	2026-06-04 16:56:05.486271	sent	7	6	\N
37	hello	f	2026-06-09 16:31:55.785808	sent	7	6	\N
38	hi have you arrived yet?	f	2026-06-09 16:32:16.753581	sent	7	6	\N
39	hello	f	2026-06-09 16:36:29.285921	sent	7	6	\N
40	hi	f	2026-06-09 16:37:18.447053	sent	6	7	\N
41	hello	f	2026-06-09 16:37:28.39692	sent	6	7	\N
42	hi hi	f	2026-06-09 16:37:59.510225	sent	6	7	\N
43	hey are there	f	2026-06-09 16:38:20.14973	sent	6	7	\N
44	hi	f	2026-06-09 16:43:09.098198	sent	7	6	\N
45	hi	f	2026-06-09 16:44:20.056166	sent	7	6	\N
46	hello how is going on where are you?	f	2026-06-09 16:44:39.534375	sent	7	6	\N
47	hello	f	2026-06-11 15:46:25.36415	sent	7	6	\N
48	hello	f	2026-06-11 15:46:25.598346	sent	7	6	\N
49	how is going on? where are you?	f	2026-06-11 15:46:42.561188	sent	7	6	\N
50	how is going on? where are you?	f	2026-06-11 15:46:42.806846	sent	7	6	\N
51	hello	f	2026-06-11 15:48:16.150405	sent	6	7	\N
52	hello 	f	2026-06-11 15:48:16.459494	sent	6	7	\N
53	hi	f	2026-06-11 16:28:58.972762	sent	7	6	\N
54	hello	f	2026-06-11 16:29:14.570097	sent	7	6	\N
55	hi	f	2026-06-11 16:29:44.581999	sent	6	7	\N
56	hi are you there	f	2026-06-11 16:30:33.240153	sent	6	7	\N
57	hello	f	2026-06-11 16:39:03.472135	sent	7	6	\N
58	hi	f	2026-06-11 16:39:14.409439	sent	7	6	\N
59	hey	f	2026-06-11 16:40:12.539699	sent	6	7	\N
60	hello Mike	f	2026-06-11 17:00:57.325946	sent	7	6	\N
61	Hi how are you?	f	2026-06-11 17:01:23.219666	sent	7	6	\N
62	Hey there	f	2026-06-11 17:01:40.618344	sent	6	7	\N
63	ffff	f	2026-06-11 17:01:51.512026	sent	6	7	\N
64	Hi	f	2026-06-12 19:31:01.183525	sent	7	6	\N
65	hello hoe are u	f	2026-06-12 19:31:43.500094	sent	7	6	\N
66	fine	f	2026-06-12 19:31:53.269397	sent	6	7	\N
67	hi arrived	f	2026-06-12 19:32:42.464607	sent	6	7	\N
68	hi	f	2026-06-17 16:16:24.266916	sent	6	7	\N
69	hello	f	2026-06-17 16:16:45.537579	sent	7	6	\N
70	hello	f	2026-06-17 16:46:58.620726	sent	6	7	\N
71	السلام عليكم	f	2026-06-19 00:52:36.190858	sent	6	7	\N
72	السلام عليكم	f	2026-06-19 00:52:53.737598	sent	6	7	\N
73	ال	f	2026-06-19 00:53:16.461461	sent	7	6	\N
74	الو	f	2026-06-19 00:53:18.279839	sent	7	6	\N
75	مرحبا	f	2026-06-19 00:55:39.140089	sent	6	7	\N
76	اهلا	f	2026-06-19 00:55:51.886897	sent	7	6	\N
77	hi	f	2026-06-20 15:00:25.325787	sent	6	7	\N
78	hello	f	2026-06-20 15:00:39.195207	sent	6	7	\N
79	heelllo	f	2026-06-20 15:06:09.922953	sent	7	6	\N
80	hi	f	2026-06-20 15:06:23.934482	sent	7	6	\N
81	hi	f	2026-06-20 15:06:36.575507	sent	6	7	\N
82	heeee	f	2026-06-20 15:07:07.353856	sent	7	6	\N
83	heeeee	f	2026-06-20 15:07:21.773513	sent	7	6	\N
84	hello	f	2026-06-20 15:07:31.618523	sent	6	7	\N
85	hi	f	2026-06-22 11:45:59.553375	sent	7	6	\N
86	have you arrived?	f	2026-06-22 11:46:14.186112	sent	7	6	\N
87	hey are you there?	f	2026-06-22 11:46:41.162983	sent	7	6	\N
88	hello	f	2026-06-22 11:46:45.393831	sent	6	7	\N
89	hi	f	2026-06-22 11:52:42.155933	sent	7	6	\N
108	hello	f	2026-06-22 21:43:40.518368	sent	7	6	140
109	hi	f	2026-06-22 21:44:03.801311	sent	7	6	140
110	hello	f	2026-06-22 21:44:14.578282	sent	7	6	140
111	hi	f	2026-06-22 21:44:20.515136	sent	6	7	140
112	hi	f	2026-06-22 21:45:16.854324	sent	7	6	140
113	hello	f	2026-06-22 21:45:26.095815	sent	6	7	140
114	hi	f	2026-06-22 21:45:47.384242	sent	7	6	140
115	hello	f	2026-06-22 21:46:00.28425	sent	6	7	140
116	hi	f	2026-06-22 21:52:27.507262	sent	7	6	141
117	hey	f	2026-06-22 21:52:39.190371	sent	6	7	141
118	hello	f	2026-06-22 21:52:48.485521	sent	7	6	141
119	hi	f	2026-06-28 10:44:09.377751	sent	7	6	\N
120	hello	f	2026-06-28 10:44:18.375999	sent	7	6	\N
121	hi	f	2026-06-28 10:44:36.42215	sent	6	7	144
122	hello	f	2026-06-28 14:13:57.930762	sent	7	6	145
123	hi	f	2026-06-28 14:14:10.03384	sent	6	7	145
124	hi	f	2026-06-28 14:15:58.368111	sent	6	7	145
125	hi	f	2026-06-28 14:17:12.194442	sent	7	6	146
126	hello	f	2026-06-28 14:17:31.431136	sent	7	6	146
127	hey	f	2026-06-28 14:18:00.048052	sent	7	6	146
128	انا وصلت	f	2026-06-28 14:18:53.977847	sent	6	7	146
129	السائق وصل	f	2026-06-28 14:19:02.865397	sent	6	7	146
130	ok	f	2026-06-28 14:19:25.184552	sent	7	6	146
131	تمام بانتظارك	f	2026-06-28 14:19:48.218252	sent	6	7	146
132	الو	f	2026-06-28 14:20:59.922412	sent	6	7	146
133	الو	f	2026-06-28 14:21:08.737666	sent	6	7	146
134	الوو	f	2026-06-28 14:21:26.043742	sent	6	7	146
135	hg,	f	2026-06-28 14:21:35.584582	sent	7	6	146
136	hi	f	2026-06-28 14:21:54.487971	sent	7	6	146
137	hi	f	2026-06-28 23:14:18.529312	sent	7	6	148
138	hello	f	2026-06-28 23:14:27.760754	sent	7	6	148
139	hello	f	2026-06-29 14:22:17.555521	sent	7	6	150
140	hi	f	2026-06-29 14:22:35.430341	sent	6	7	150
141	how is going	f	2026-06-29 14:22:52.001182	sent	7	6	150
142	fine	f	2026-06-29 14:23:01.604989	sent	6	7	150
143	have you arrived ?	f	2026-06-29 14:23:23.54834	sent	7	6	150
144	yes	f	2026-06-29 14:23:30.702297	sent	6	7	150
145	hello	f	2026-06-29 14:41:41.553755	sent	7	6	151
146	hi	f	2026-06-29 14:41:52.374589	sent	7	6	151
147	hi	f	2026-06-29 15:13:02.397341	sent	7	6	157
148	hello	f	2026-06-29 15:13:14.169503	sent	7	6	157
149	hey	f	2026-06-29 15:13:23.61731	sent	6	7	157
150	how is going	f	2026-06-29 15:13:33.01722	sent	6	7	157
151	hi	f	2026-06-30 00:10:25.670785	sent	6	7	158
152	السلام عليكم متى توصل ؟	f	2026-06-30 09:52:51.149958	sent	7	6	159
153	وعليكم السلام ثواني	f	2026-06-30 09:53:29.44597	sent	6	7	159
154	مرحبا	f	2026-06-30 09:53:48.858359	sent	6	7	159
155	أنا وصلت	f	2026-06-30 09:54:04.912724	sent	6	7	159
156	مرحبا	f	2026-06-30 09:59:55.525115	sent	7	6	160
157	وصلت	f	2026-06-30 10:00:15.285053	sent	6	7	160
158	hello	f	2026-06-30 11:40:35.867264	sent	7	6	164
159	hi	f	2026-06-30 11:41:27.571342	sent	6	7	164
160	he	f	2026-06-30 11:41:39.961801	sent	6	7	164
161	مرحبا لقد وصلت	f	2026-06-30 21:04:44.985691	sent	6	7	169
162	نازله	f	2026-06-30 21:05:10.356726	sent	7	6	169
163	لا تتاخري يا حرمة عنا شغل	f	2026-06-30 21:05:33.609012	sent	6	7	169
164	في مندوب	f	2026-06-30 21:05:44.432939	sent	7	6	169
165	اخد الاصانصير	f	2026-06-30 21:05:51.702119	sent	7	6	169
166	طيب عادي	f	2026-06-30 21:06:01.362493	sent	6	7	169
167	استني ما في تلبك	f	2026-06-30 21:06:11.22739	sent	6	7	169
168	السلام عليكم	f	2026-07-01 16:31:50.772376	sent	7	6	171
169	ii	f	2026-07-01 16:32:27.811619	sent	6	7	\N
170	الو	f	2026-07-01 16:32:31.268327	sent	6	7	\N
171	تتتت	f	2026-07-01 16:32:39.582522	sent	7	6	171
172	هلو	f	2026-07-01 16:32:52.819111	sent	7	6	171
173	مرحب	f	2026-07-01 19:28:55.995129	sent	7	6	172
174	اهلا	f	2026-07-01 19:29:16.94433	sent	6	7	172
175	هاي	f	2026-07-02 20:44:35.859453	sent	7	6	174
176	انا وصلت	f	2026-07-02 20:48:46.211757	sent	6	7	174
177	انزلو	f	2026-07-02 20:48:52.836814	sent	6	7	174
178	انا ااسائق وصلت	f	2026-07-02 21:32:28.675638	sent	6	7	175
179	متى تنزلي حضرتك ؟؟	f	2026-07-02 21:32:38.5937	sent	6	7	175
180	انزلي	f	2026-07-03 19:36:15.321563	sent	6	7	181
181	انزلي حبي	f	2026-07-03 19:37:43.116366	sent	6	7	181
182	وصلت انزلي	f	2026-07-03 21:21:05.710278	sent	6	7	183
183	انا وصلت انزلي	f	2026-07-05 21:53:37.292635	sent	6	7	184
184	مرحبا	f	2026-07-05 22:56:19.738791	sent	1	7	186
185	اهلا	f	2026-07-05 22:56:32.298986	sent	7	1	186
186	كيفك	f	2026-07-05 22:56:38.314105	sent	7	1	186
187	عبتشوفي	f	2026-07-06 20:33:27.814188	sent	6	14	189
188	عم تراقبي الرحلة	f	2026-07-06 20:33:38.722026	sent	6	14	189
189	ال	f	2026-07-06 20:33:46.526356	sent	6	14	189
190	مرحبا	f	2026-07-06 21:43:29.400398	sent	11	14	192
191	hi	f	2026-07-06 21:43:40.130537	sent	14	11	192
192	اهلين انت وصلت	f	2026-07-07 00:08:12.787466	sent	7	6	197
193	اي وصلت	f	2026-07-07 00:08:28.491998	sent	6	7	197
194	مرحب	f	2026-07-07 10:00:50.488614	sent	7	6	198
195	555	f	2026-07-07 10:01:31.514327	sent	6	7	198
196	hi	f	2026-07-09 15:48:17.082273	sent	6	7	207
197	hello	f	2026-07-09 15:48:30.775794	sent	7	6	207
198	how is going	f	2026-07-09 15:48:50.595108	sent	7	6	207
199	hey	f	2026-07-09 15:48:59.330251	sent	6	7	207
200	fine	f	2026-07-09 15:49:09.456041	sent	6	7	207
201	وصلت	f	2026-07-09 21:35:22.934299	sent	11	13	212
202	انزلي بسرعة	f	2026-07-09 21:35:42.607931	sent	11	13	212
203	الوو	f	2026-07-09 21:36:48.484523	sent	11	13	212
204	الو	f	2026-07-09 22:43:24.456582	sent	13	11	213
205	انا وصلت	f	2026-07-10 17:47:11.159798	sent	11	13	216
206	انزلو فورا	f	2026-07-10 17:47:16.506903	sent	11	13	216
207	الو	f	2026-07-10 19:22:59.531966	sent	13	11	217
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, body, created_at, is_read, related_user_id, title, type, user_id) FROM stdin;
99	hg,	2026-06-28 14:21:35.591921	f	6	New message from rider2	chat_message	7
100	hi	2026-06-28 14:21:54.499419	f	6	New message from rider2	chat_message	7
103	hello	2026-06-29 14:22:17.617234	f	6	New message from rider2	chat_message	7
104	hi	2026-06-29 14:22:35.436376	f	7	New message from driver2	chat_message	6
105	how is going	2026-06-29 14:22:52.003177	f	6	New message from rider2	chat_message	7
106	fine	2026-06-29 14:23:01.608988	f	7	New message from driver2	chat_message	6
107	have you arrived ?	2026-06-29 14:23:23.555849	f	6	New message from rider2	chat_message	7
108	yes	2026-06-29 14:23:30.710643	f	7	New message from driver2	chat_message	6
109	hello	2026-06-29 14:41:41.576888	f	6	New message from rider2	chat_message	7
110	hi	2026-06-29 14:41:52.378582	f	6	New message from rider2	chat_message	7
111	hi	2026-06-29 15:13:02.428661	f	6	New message from rider2	chat_message	7
112	hello	2026-06-29 15:13:14.181046	f	6	New message from rider2	chat_message	7
113	hey	2026-06-29 15:13:23.621319	f	7	New message from driver2	chat_message	6
114	how is going	2026-06-29 15:13:33.022143	f	7	New message from driver2	chat_message	6
115	hi	2026-06-30 00:10:27.528229	f	7	New message from driver2	chat_message	6
116	السلام عليكم متى توصل ؟	2026-06-30 09:52:51.198834	f	6	New message from rider2	chat_message	7
117	وعليكم السلام ثواني	2026-06-30 09:53:29.452479	f	7	New message from driver2	chat_message	6
118	مرحبا	2026-06-30 09:53:48.867378	f	7	New message from driver2	chat_message	6
119	أنا وصلت	2026-06-30 09:54:04.912724	f	7	New message from driver2	chat_message	6
120	مرحبا	2026-06-30 09:59:55.540879	f	6	New message from rider2	chat_message	7
121	وصلت	2026-06-30 10:00:15.287047	f	7	New message from driver2	chat_message	6
72	hello	2026-06-22 21:43:40.550442	t	6	New message from rider2	chat_message	7
73	hi	2026-06-22 21:44:03.806321	t	6	New message from rider2	chat_message	7
74	hello	2026-06-22 21:44:14.588071	t	6	New message from rider2	chat_message	7
76	hi	2026-06-22 21:45:16.857317	t	6	New message from rider2	chat_message	7
78	hi	2026-06-22 21:45:47.388241	t	6	New message from rider2	chat_message	7
80	hi	2026-06-22 21:52:27.519226	t	6	New message from rider2	chat_message	7
82	hello	2026-06-22 21:52:48.492327	t	6	New message from rider2	chat_message	7
122	hello	2026-06-30 11:40:35.911781	f	6	New message from rider2	chat_message	7
123	hi	2026-06-30 11:41:27.579301	f	7	New message from driver2	chat_message	6
124	he	2026-06-30 11:41:39.963808	f	7	New message from driver2	chat_message	6
125	مرحبا لقد وصلت	2026-06-30 21:04:45.013618	f	7	New message from driver2	chat_message	6
83	hi	2026-06-28 10:44:09.502664	f	6	New message from rider2	chat_message	7
84	hello	2026-06-28 10:44:18.381526	f	6	New message from rider2	chat_message	7
126	نازله	2026-06-30 21:05:10.36075	f	6	New message from rider2	chat_message	7
127	لا تتاخري يا حرمة عنا شغل	2026-06-30 21:05:33.617628	f	7	New message from driver2	chat_message	6
128	في مندوب	2026-06-30 21:05:44.437921	f	6	New message from rider2	chat_message	7
101	hi	2026-06-28 23:14:18.570538	f	6	New message from rider2	chat_message	7
102	hello	2026-06-28 23:14:27.767735	f	6	New message from rider2	chat_message	7
86	hello	2026-06-28 14:13:58.084511	f	6	New message from rider2	chat_message	7
129	اخد الاصانصير	2026-06-30 21:05:51.705111	f	6	New message from rider2	chat_message	7
130	طيب عادي	2026-06-30 21:06:01.365313	f	7	New message from driver2	chat_message	6
131	استني ما في تلبك	2026-06-30 21:06:11.232624	f	7	New message from driver2	chat_message	6
132	السلام عليكم	2026-07-01 16:31:50.788259	f	6	New message from rider2	chat_message	7
133	ii	2026-07-01 16:32:27.82731	f	7	New message from driver2	chat_message	6
134	الو	2026-07-01 16:32:31.281597	f	7	New message from driver2	chat_message	6
135	تتتت	2026-07-01 16:32:39.588532	f	6	New message from rider2	chat_message	7
89	hi	2026-06-28 14:17:12.229217	f	6	New message from rider2	chat_message	7
90	hello	2026-06-28 14:17:31.485525	f	6	New message from rider2	chat_message	7
91	hey	2026-06-28 14:18:00.056685	f	6	New message from rider2	chat_message	7
94	ok	2026-06-28 14:19:25.194432	f	6	New message from rider2	chat_message	7
98	الوو	2026-06-28 14:21:26.047277	t	7	New message from driver2	chat_message	6
75	hi	2026-06-22 21:44:20.515136	t	7	New message from driver2	chat_message	6
77	hello	2026-06-22 21:45:26.097797	t	7	New message from driver2	chat_message	6
79	hello	2026-06-22 21:46:00.287246	t	7	New message from driver2	chat_message	6
81	hey	2026-06-22 21:52:39.194626	t	7	New message from driver2	chat_message	6
85	hi	2026-06-28 10:44:36.436522	t	7	New message from driver2	chat_message	6
87	hi	2026-06-28 14:14:10.038045	t	7	New message from driver2	chat_message	6
88	hi	2026-06-28 14:15:58.395459	t	7	New message from driver2	chat_message	6
92	انا وصلت	2026-06-28 14:18:53.996649	t	7	New message from driver2	chat_message	6
93	السائق وصل	2026-06-28 14:19:02.871795	t	7	New message from driver2	chat_message	6
95	تمام بانتظارك	2026-06-28 14:19:48.241204	t	7	New message from driver2	chat_message	6
96	الو	2026-06-28 14:20:59.933196	t	7	New message from driver2	chat_message	6
97	الو	2026-06-28 14:21:08.744684	t	7	New message from driver2	chat_message	6
136	هلو	2026-07-01 16:32:52.819111	f	6	New message from rider2	chat_message	7
137	مرحب	2026-07-01 19:28:56.014579	f	6	New message from rider2	chat_message	7
138	اهلا	2026-07-01 19:29:16.953258	f	7	New message from driver2	chat_message	6
139	هاي	2026-07-02 20:44:35.869132	f	6	New message from rider2	chat_message	7
140	انا وصلت	2026-07-02 20:48:46.219134	f	7	New message from driver2	chat_message	6
141	انزلو	2026-07-02 20:48:52.836814	f	7	New message from driver2	chat_message	6
142	انا ااسائق وصلت	2026-07-02 21:32:28.675638	f	7	New message from driver2	chat_message	6
143	متى تنزلي حضرتك ؟؟	2026-07-02 21:32:38.5937	f	7	New message from driver2	chat_message	6
144	انزلي	2026-07-03 19:36:15.344217	f	7	New message from driver2	chat_message	6
145	انزلي حبي	2026-07-03 19:37:43.122227	f	7	New message from driver2	chat_message	6
146	وصلت انزلي	2026-07-03 21:21:05.757674	f	7	New message from driver2	chat_message	6
147	انا وصلت انزلي	2026-07-05 21:53:37.324689	f	7	New message from driver2	chat_message	6
148	مرحبا	2026-07-05 22:56:19.763944	f	7	New message from driver2	chat_message	1
149	اهلا	2026-07-05 22:56:32.30407	f	1	New message from null	chat_message	7
150	كيفك	2026-07-05 22:56:38.317135	f	1	New message from null	chat_message	7
151	عبتشوفي	2026-07-06 20:33:27.845767	f	14	New message from muasiassi	chat_message	6
152	عم تراقبي الرحلة	2026-07-06 20:33:38.73205	f	14	New message from muasiassi	chat_message	6
153	ال	2026-07-06 20:33:46.526356	f	14	New message from muasiassi	chat_message	6
154	مرحبا	2026-07-06 21:43:29.416024	f	14	New message from muasiassi	chat_message	11
155	hi	2026-07-06 21:43:40.130537	f	11	New message from diarjojo89	chat_message	14
156	اهلين انت وصلت	2026-07-07 00:08:12.805552	f	6	New message from rider2	chat_message	7
157	اي وصلت	2026-07-07 00:08:28.499092	f	7	New message from driver2	chat_message	6
158	مرحب	2026-07-07 10:00:50.503634	f	6	New message from rider2	chat_message	7
159	555	2026-07-07 10:01:31.51732	f	7	New message from driver2	chat_message	6
160	hi	2026-07-09 15:48:17.113564	f	7	New message from driver2	chat_message	6
161	hello	2026-07-09 15:48:30.775794	f	6	New message from rider2	chat_message	7
162	how is going	2026-07-09 15:48:50.599105	f	6	New message from rider2	chat_message	7
163	hey	2026-07-09 15:48:59.333479	f	7	New message from driver2	chat_message	6
164	fine	2026-07-09 15:49:09.456041	f	7	New message from driver2	chat_message	6
165	وصلت	2026-07-09 21:35:22.971241	f	13	New message from muasi	chat_message	11
166	انزلي بسرعة	2026-07-09 21:35:42.614513	f	13	New message from muasi	chat_message	11
167	الوو	2026-07-09 21:36:48.493281	f	13	New message from muasi	chat_message	11
168	الو	2026-07-09 22:43:24.495869	f	11	New message from diarjojo89	chat_message	13
169	انا وصلت	2026-07-10 17:47:11.189151	f	13	New message from muasi	chat_message	11
170	انزلو فورا	2026-07-10 17:47:16.509896	f	13	New message from muasi	chat_message	11
171	الو	2026-07-10 19:22:59.531966	f	11	New message from diarjojo89	chat_message	13
\.


--
-- Data for Name: otp_codes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.otp_codes (id, code, created_at, email, expires_at, used) FROM stdin;
8	161734	2026-07-06 15:16:47.802316	eng.mustafa83@yahoo.com	2026-07-06 15:26:47.802316	t
9	673388	2026-07-06 15:24:01.10905	eng.mustafa83@yahoo.com	2026-07-06 15:34:01.10905	t
10	669533	2026-07-06 16:27:34.733188	muasiassi@gmail.com	2026-07-06 16:37:34.733188	t
11	273407	2026-07-06 21:40:32.909007	diarjojo89@gmail.com	2026-07-06 21:50:32.909007	t
1	301001	2026-05-05 16:40:03.062308	muasi@yahoo.com	2026-05-05 16:50:03.061304	t
17	067069	2026-07-09 00:32:58.969946	muasi@yahoo.com	2026-07-09 00:42:58.969946	t
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, ride_id, amount, payment_method, status, transaction_id, created_at, completed_at) FROM stdin;
56	139	2.06	WALLET	PENDING	\N	2026-06-22 17:06:22.586333	\N
57	140	3.55	WALLET	PENDING	\N	2026-06-22 21:46:08.843498	\N
58	141	2.58	WALLET	PENDING	\N	2026-06-22 21:53:48.191646	\N
59	142	2.82	WALLET	PENDING	\N	2026-06-22 22:07:22.394236	\N
60	143	2.88	WALLET	PENDING	\N	2026-06-22 22:17:16.874198	\N
61	144	8.21	WALLET	PENDING	\N	2026-06-28 10:45:55.111464	\N
62	148	2.13	WALLET	PENDING	\N	2026-06-28 23:17:25.70113	\N
63	156	2.57	WALLET	COMPLETED	\N	2026-06-29 15:00:58.084463	2026-06-29 15:01:12.426779
64	157	2.57	WALLET	COMPLETED	\N	2026-06-29 15:15:27.799744	2026-06-29 15:15:38.875742
65	159	9.59	WALLET	COMPLETED	\N	2026-06-30 09:55:32.365118	2026-06-30 09:55:58.73129
66	169	2.15	WALLET	COMPLETED	\N	2026-06-30 21:10:55.656736	2026-06-30 21:11:11.295632
67	170	2.11	WALLET	COMPLETED	\N	2026-06-30 21:16:30.020037	2026-06-30 21:16:35.205212
68	171	2.11	WALLET	PENDING	\N	2026-07-01 16:36:10.202746	\N
69	172	2.11	WALLET	COMPLETED	\N	2026-07-01 19:33:22.427504	2026-07-01 19:33:29.585969
70	174	2.12	WALLET	COMPLETED	\N	2026-07-02 20:52:00.158996	2026-07-02 20:52:05.742688
71	175	2.87	WALLET	PENDING	\N	2026-07-02 21:48:09.194174	\N
72	179	3.34	WALLET	COMPLETED	\N	2026-07-03 18:27:39.118726	2026-07-03 18:27:43.765395
73	183	2.88	WALLET	COMPLETED	\N	2026-07-03 21:26:51.471229	2026-07-03 21:27:01.658645
74	184	2.04	WALLET	PENDING	\N	2026-07-05 21:56:53.232531	\N
75	186	2.13	WALLET	PENDING	\N	2026-07-05 22:57:19.866681	\N
76	188	2.17	WALLET	PENDING	\N	2026-07-05 23:01:01.731302	\N
77	197	6.17	WALLET	COMPLETED	\N	2026-07-07 00:09:11.525477	2026-07-07 00:09:15.696636
78	198	2.94	WALLET	COMPLETED	\N	2026-07-07 10:01:42.544126	2026-07-07 10:01:51.896293
79	199	2.07	WALLET	PENDING	\N	2026-07-08 18:36:40.727513	\N
80	200	2.63	WALLET	PENDING	\N	2026-07-08 20:37:34.78011	\N
81	201	2.94	WALLET	PENDING	\N	2026-07-08 23:09:05.625639	\N
82	202	2.94	WALLET	PENDING	\N	2026-07-08 23:33:53.812701	\N
83	204	2.94	CASH	FAILED	\N	2026-07-08 23:56:40.967158	\N
84	206	2.94	CASH	COMPLETED	\N	2026-07-09 00:04:02.049748	2026-07-09 00:04:19.441917
85	207	2.94	CASH	PENDING	\N	2026-07-09 15:50:08.1526	\N
86	208	2.94	CASH	PENDING	\N	2026-07-09 15:51:55.22592	\N
87	209	2.94	CASH	COMPLETED	\N	2026-07-09 15:55:57.681598	2026-07-09 15:56:10.398069
88	211	2.94	CASH	COMPLETED	\N	2026-07-09 16:00:40.505924	2026-07-09 16:00:49.607021
89	212	2.94	CASH	COMPLETED	\N	2026-07-09 21:42:25.844114	2026-07-09 21:42:34.530025
90	213	3.81	CASH	COMPLETED	\N	2026-07-09 22:43:58.387611	2026-07-09 22:44:06.474508
91	214	2.11	CASH	COMPLETED	\N	2026-07-10 17:22:11.94362	2026-07-10 17:22:24.10432
92	215	2.11	CASH	COMPLETED	\N	2026-07-10 17:24:13.720731	2026-07-10 17:24:29.406502
93	216	3.68	CASH	PENDING	\N	2026-07-10 18:02:45.19294	\N
94	217	11.55	CASH	COMPLETED	\N	2026-07-10 19:24:53.095077	2026-07-10 19:25:00.714113
\.


--
-- Data for Name: profile_photos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profile_photos (id, photo_url, uploaded_at, user_id) FROM stdin;
\.


--
-- Data for Name: ratings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ratings (id, ride_id, rater_id, ratee_id, rating, feedback, created_at) FROM stdin;
8	179	6	7	5		2026-07-03 18:27:55.280032
9	197	6	7	5	رأئع	2026-07-07 00:09:32.36934
10	211	13	6	5	good	2026-07-09 16:01:00.462385
11	212	11	13	5		2026-07-09 21:42:43.562705
12	213	11	13	5	روعه	2026-07-09 22:44:32.926348
13	214	11	13	5		2026-07-10 17:22:23.534468
14	216	11	13	5		2026-07-10 18:02:54.314851
15	217	11	13	5		2026-07-10 19:25:01.156977
\.


--
-- Data for Name: ride_audit_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ride_audit_events (id, actor, actor_id, actor_name, city, correlation_id, country, created_at, details, event_type, keep_forever, latitude, longitude, ride_id, "timestamp") FROM stdin;
1	RIDER	6	John Rider	\N	51a599b4-7941-446e-88ec-78d0a1b2f336	\N	2026-07-06 16:45:51.720961	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-06 16:45:51.71996
2	SYSTEM	6	\N	\N	8d80fbc7-ab46-443e-a8b6-28bd5a5f6064	\N	2026-07-06 16:45:52.751776	{"sessionId": "5c31a04b-9c90-6719-d5e2-edecc4440441"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 16:45:52.751776
3	SYSTEM	6	\N	\N	f3e0299b-6161-4976-ad85-0532437127ba	\N	2026-07-06 16:46:02.18957	{"reason": "", "sessionId": "5c31a04b-9c90-6719-d5e2-edecc4440441"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 16:46:02.18957
4	DRIVER	7	Mike Driver	\N	e0029e81-c30c-4e34-9754-23062fcc5705	\N	2026-07-06 16:46:07.574654	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-06 16:46:07.573655
5	SYSTEM	7	\N	\N	a2b697d1-472e-4433-ac0d-e05a835ce5d6	\N	2026-07-06 16:46:08.240267	{"sessionId": "73847f96-aa7c-15b7-8447-836ebcbb3448"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 16:46:08.240267
6	SYSTEM	7	\N	\N	c2964f81-e3e9-4f32-aad5-78084bbd8782	\N	2026-07-06 16:46:13.204464	{"reason": "", "sessionId": "73847f96-aa7c-15b7-8447-836ebcbb3448"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 16:46:13.204464
7	DRIVER	14	Mustaasai	\N	64c72d59-53dd-4fce-a4c9-ad97201daf53	\N	2026-07-06 20:21:31.290019	{"email": "muasiassi@gmail.com"}	LOGIN	f	\N	\N	\N	2026-07-06 20:21:31.290019
8	SYSTEM	14	\N	\N	52f19034-cc11-4695-b549-e27a0950f887	\N	2026-07-06 20:21:32.761068	{"sessionId": "9d80e16d-682e-56a1-ea6f-916464312af4"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:21:32.761068
9	SYSTEM	14	\N	\N	c00619dc-d0bd-4425-9c00-514606a3e3d3	\N	2026-07-06 20:22:17.559722	{"reason": "", "sessionId": "9d80e16d-682e-56a1-ea6f-916464312af4"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:22:17.558722
10	RIDER	6	John Rider	\N	8d60b9c9-fb94-4f13-a834-a5b2b01b0909	\N	2026-07-06 20:23:34.451893	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-06 20:23:34.451893
11	SYSTEM	6	\N	\N	1c21361b-700a-418c-b528-e8e2dae06789	\N	2026-07-06 20:23:35.308104	{"sessionId": "3255ab87-ca01-3a15-acec-ef40464cafe8"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:23:35.308104
12	RIDER	6	John Rider	\N	9e0e2091-b440-4338-aa42-841fe233f8c9	\N	2026-07-06 20:25:03.037529	{"rideType": "ECONOMY", "estimatedFare": 4.01, "pickupAddress": "KSA-DHA-Gharb Al Dhahran-Ring Road", "dropoffAddress": "KSA-الد-حي الفردوس-1ب", "estimatedDistance": 10.052, "estimatedDuration": 14}	RIDE_REQUESTED	f	\N	\N	189	2026-07-06 20:25:03.037529
13	DRIVER	14	Mustaasai	\N	238839c4-04a7-4d4b-acba-48a10fdbc2f7	\N	2026-07-06 20:25:20.431736	{"driverId": 14, "driverName": "Mustaasai"}	RIDE_ACCEPTED	f	\N	\N	189	2026-07-06 20:25:20.431736
14	SYSTEM	6	\N	\N	b55ccd61-64fe-44ad-8b7a-c7e3f51a15bf	\N	2026-07-06 20:32:29.22942	{"reason": "", "sessionId": "3255ab87-ca01-3a15-acec-ef40464cafe8"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:32:29.22942
15	SYSTEM	6	\N	\N	771cb70e-1015-4f13-a8af-f1d4eb41ad9b	\N	2026-07-06 20:32:33.968662	{"sessionId": "1dc5d9b3-eb29-acb5-cbb5-ff9ad77a7808"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:32:33.968662
16	DRIVER	14	Mustaasai	\N	6a6266dd-b990-4058-87ad-071852989a30	\N	2026-07-06 20:38:53.237968	{}	DRIVER_ARRIVED	f	\N	\N	189	2026-07-06 20:38:53.237968
17	DRIVER	14	Mustaasai	\N	a479e8a5-1534-4342-aea8-b41ab7e81750	\N	2026-07-06 20:41:08.322728	{}	RIDE_STARTED	f	\N	\N	189	2026-07-06 20:41:08.322728
18	SYSTEM	6	\N	\N	0b54cec5-0941-47fa-9109-90153e27f426	\N	2026-07-06 20:41:12.154037	{"sessionId": "c611bfbe-46d5-e29d-702e-9795661af5f0"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:41:12.154037
19	SYSTEM	6	\N	\N	c9eea3c0-09b0-495c-ac22-23d62aa10da2	\N	2026-07-06 20:41:12.562849	{"reason": "", "sessionId": "1dc5d9b3-eb29-acb5-cbb5-ff9ad77a7808"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:41:12.562849
20	RIDER	6	John Rider	\N	d8c75787-d4d8-45c8-8751-f9ce5ef77997	\N	2026-07-06 20:41:54.457682	{"reason": "User logged out"}	RIDE_CANCELLED	f	\N	\N	189	2026-07-06 20:41:54.457682
21	SYSTEM	6	\N	\N	eb974af9-372e-4fd8-bd82-babdbb04bd1e	\N	2026-07-06 20:41:55.023864	{"reason": "", "sessionId": "c611bfbe-46d5-e29d-702e-9795661af5f0"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:41:55.023864
22	RIDER	6	John Rider	\N	5c2edcc5-608e-487a-bfcf-d7b9cdd03430	\N	2026-07-06 20:41:57.592342	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-06 20:41:57.592342
23	SYSTEM	6	\N	\N	a5252a7c-6521-4bd9-ba6a-edd91725a07a	\N	2026-07-06 20:41:58.513512	{"sessionId": "a016614c-a1e4-d120-e458-737d398f3196"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:41:58.513512
24	SYSTEM	6	\N	\N	46293a60-4b21-4b27-aabf-789eb700f2ba	\N	2026-07-06 20:43:31.430047	{"reason": "", "sessionId": "a016614c-a1e4-d120-e458-737d398f3196"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:43:31.430047
25	SYSTEM	6	\N	\N	8d96d8f9-5193-484c-9184-e294122cfd67	\N	2026-07-06 20:48:46.646327	{"sessionId": "9f168c6e-6e9d-b292-20a3-74ae8957f76d"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:48:46.646327
26	SYSTEM	14	\N	\N	657b9954-47a0-4521-b101-472fd31d493e	\N	2026-07-06 20:51:30.05491	{"sessionId": "e76c40d2-749e-692b-a468-0352d1caac54"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:51:30.05491
27	RIDER	6	John Rider	\N	3a0848fa-1ef6-42c0-99b2-9e0925f2d915	\N	2026-07-06 20:52:10.622097	{"rideType": "ECONOMY", "estimatedFare": 2.13, "pickupAddress": "KSA-DAM-Hajar-Prince Mohammed Bin", "dropoffAddress": "KSA-الد-حي الفردوس-1ب", "estimatedDistance": 0.647, "estimatedDuration": 2}	RIDE_REQUESTED	f	\N	\N	190	2026-07-06 20:52:10.622097
28	DRIVER	14	Mustaasai	\N	12ad4137-f385-4c61-a2e3-0b3ff2be262d	\N	2026-07-06 20:52:13.348319	{"driverId": 14, "driverName": "Mustaasai"}	RIDE_ACCEPTED	f	\N	\N	190	2026-07-06 20:52:13.348319
29	DRIVER	14	Mustaasai	\N	a003ed27-d96a-4625-a938-fb1d512f884f	\N	2026-07-06 20:52:18.370384	{}	DRIVER_ARRIVED	f	\N	\N	190	2026-07-06 20:52:18.370384
30	SYSTEM	6	\N	\N	82dea9d8-04cc-4624-bdfa-1a4ce2fac97d	\N	2026-07-06 20:52:34.964047	{"reason": "", "sessionId": "9f168c6e-6e9d-b292-20a3-74ae8957f76d"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:52:34.964047
31	SYSTEM	6	\N	\N	b63561cd-666f-4fd5-a2b8-5741c4a2bf15	\N	2026-07-06 20:52:42.384681	{"sessionId": "c5147e83-aefa-442d-873d-5a2c4709db43"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:52:42.384681
32	DRIVER	14	Mustaasai	\N	38789292-33f3-4827-9da5-1567c26781af	\N	2026-07-06 20:53:33.737043	{"reason": ""}	RIDE_CANCELLED	f	\N	\N	190	2026-07-06 20:53:33.737043
33	SYSTEM	14	\N	\N	cedee69a-1cd7-4cf7-bbf9-6e0ed185e7d9	\N	2026-07-06 20:53:34.15969	{"reason": "", "sessionId": "e76c40d2-749e-692b-a468-0352d1caac54"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:53:34.15969
34	SYSTEM	14	\N	\N	421f9adb-687d-4416-a37c-84801373418d	\N	2026-07-06 20:53:34.603581	{"sessionId": "e23c2c3f-739e-c69e-cf56-c103aadfa4ab"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:53:34.603581
35	RIDER	6	John Rider	\N	abda601e-27f5-45cf-b518-8deac99364f0	\N	2026-07-06 20:53:57.724093	{"rideType": "ECONOMY", "estimatedFare": 2.11, "pickupAddress": "KSA-DAM-Hajar-619", "dropoffAddress": "KSA-DAM-Hajar-Balaghah Street", "estimatedDistance": 0.526, "estimatedDuration": 2}	RIDE_REQUESTED	f	\N	\N	191	2026-07-06 20:53:57.724093
36	DRIVER	14	Mustaasai	\N	ee1c1c43-aa0d-4d2f-8674-250e5673e438	\N	2026-07-06 20:53:59.626118	{"driverId": 14, "driverName": "Mustaasai"}	RIDE_ACCEPTED	f	\N	\N	191	2026-07-06 20:53:59.626118
37	DRIVER	14	Mustaasai	\N	37b844b4-970b-4982-b92c-53c6c0e41dce	\N	2026-07-06 20:55:01.129683	{}	DRIVER_ARRIVED	f	\N	\N	191	2026-07-06 20:55:01.129683
38	SYSTEM	6	\N	\N	0fa00b4e-a294-4862-8ed8-984b26ef5cd0	\N	2026-07-06 20:55:07.327883	{"reason": "", "sessionId": "c5147e83-aefa-442d-873d-5a2c4709db43"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:55:07.327883
39	SYSTEM	6	\N	\N	5039b1a4-52a0-4c70-97ec-d810c4f9b43b	\N	2026-07-06 20:55:13.087787	{"sessionId": "b5590a4c-d662-cdda-02a4-a7813ea3e1c3"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 20:55:13.087787
40	SYSTEM	14	\N	\N	3d7f2ab4-a8fe-4749-8483-d9d89190ec71	\N	2026-07-06 20:55:29.539498	{"reason": "", "sessionId": "e23c2c3f-739e-c69e-cf56-c103aadfa4ab"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:55:29.539498
41	SYSTEM	6	\N	\N	8dd2150d-5dd7-4bf1-827e-12dd9604edac	\N	2026-07-06 20:56:05.47093	{"reason": "", "sessionId": "b5590a4c-d662-cdda-02a4-a7813ea3e1c3"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 20:56:05.47093
42	SYSTEM	6	\N	\N	28ddd3a8-3e1a-4ad2-8483-9bcce692c944	\N	2026-07-06 21:39:36.295925	{"sessionId": "939ca72e-4266-3073-ef04-912d815a51fb"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:39:36.295925
43	RIDER	6	John Rider	\N	3b8ab60c-17a2-4634-bb1a-f0148c221afc	\N	2026-07-06 21:39:43.144294	{"reason": "User logged out"}	RIDE_CANCELLED	f	\N	\N	191	2026-07-06 21:39:43.144294
44	SYSTEM	6	\N	\N	5d2d58bc-ed40-4773-8c5c-51eae8eabdc9	\N	2026-07-06 21:39:43.562657	{"reason": "", "sessionId": "939ca72e-4266-3073-ef04-912d815a51fb"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:39:43.562657
45	RIDER	11	jomana	\N	394e9517-9b41-4a67-80a4-f23dc5583dc5	\N	2026-07-06 21:42:34.629047	{"email": "diarjojo89@gmail.com"}	LOGIN	f	\N	\N	\N	2026-07-06 21:42:34.629047
46	SYSTEM	11	\N	\N	212592f6-b7cd-4ecc-aabd-d74809c01e47	\N	2026-07-06 21:42:35.333835	{"sessionId": "4865aeeb-a1bd-7510-c240-0761dbb04218"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:42:35.333835
47	SYSTEM	14	\N	\N	009c0662-669d-4770-8ee7-7966d000d53a	\N	2026-07-06 21:43:02.430323	{"sessionId": "828c0c71-c607-b62f-e070-6aeb47e0d7e7"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:43:02.430323
48	RIDER	11	jomana	\N	114ea0a7-ac98-49d1-8a82-a9e988fa3a77	\N	2026-07-06 21:43:12.094108	{"rideType": "ECONOMY", "estimatedFare": 2.41, "pickupAddress": "KSA-الد-حي الفردوس-1ب", "dropoffAddress": "KSA-DAM-حي المنتزه-10", "estimatedDistance": 2.041, "estimatedDuration": 4}	RIDE_REQUESTED	f	\N	\N	192	2026-07-06 21:43:12.094108
49	DRIVER	14	Mustaasai	\N	fb16741d-968d-43dc-ad3b-bb20b3a03695	\N	2026-07-06 21:43:15.560433	{"driverId": 14, "driverName": "Mustaasai"}	RIDE_ACCEPTED	f	\N	\N	192	2026-07-06 21:43:15.560433
50	SYSTEM	11	\N	\N	857e0898-d8d3-468f-99e2-6838c1cefba9	\N	2026-07-06 21:45:22.589013	{"reason": "", "sessionId": "4865aeeb-a1bd-7510-c240-0761dbb04218"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:45:22.589013
51	SYSTEM	11	\N	\N	5ed10e59-8c3a-4598-9a76-18ff1402dba5	\N	2026-07-06 21:45:28.286204	{"sessionId": "0691a82d-ed64-9d79-49b7-9fd75c0efe83"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:45:28.286204
52	DRIVER	14	Mustaasai	\N	cf14678c-29eb-4771-9ac9-dc9dbe52490c	\N	2026-07-06 21:46:16.782909	{"reason": ""}	RIDE_CANCELLED	f	\N	\N	192	2026-07-06 21:46:16.782909
53	SYSTEM	14	\N	\N	1455f9fd-655e-43af-bdf7-20837ab7c4a9	\N	2026-07-06 21:46:17.017101	{"reason": "", "sessionId": "828c0c71-c607-b62f-e070-6aeb47e0d7e7"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:46:17.017101
54	SYSTEM	14	\N	\N	8eb4aa29-abe7-49e8-8416-1eca941f8430	\N	2026-07-06 21:46:17.279197	{"sessionId": "bce14497-b1ac-150c-c429-1bd70930b425"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:46:17.279197
55	RIDER	11	jomana	\N	173e7965-76ca-435a-8065-1b27486b05f6	\N	2026-07-06 21:46:27.959393	{"rideType": "ECONOMY", "estimatedFare": 2.39, "pickupAddress": "KSA-DAM-حي الفردوس-1ب", "dropoffAddress": "KSA-DAM-حي المنتزه-المسك", "estimatedDistance": 1.927, "estimatedDuration": 5}	RIDE_REQUESTED	f	\N	\N	193	2026-07-06 21:46:27.959393
56	DRIVER	14	Mustaasai	\N	4f52e682-2ce7-4efa-a05a-0b43ad8bf459	\N	2026-07-06 21:46:30.251353	{"driverId": 14, "driverName": "Mustaasai"}	RIDE_ACCEPTED	f	\N	\N	193	2026-07-06 21:46:30.251353
57	SYSTEM	11	\N	\N	a3abeb8e-77cb-44a3-a4e2-9e06e84b3b81	\N	2026-07-06 21:46:37.582686	{"reason": "", "sessionId": "0691a82d-ed64-9d79-49b7-9fd75c0efe83"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:46:37.582686
58	SYSTEM	11	\N	\N	9a630ad6-8a2f-42e9-833f-943f13976645	\N	2026-07-06 21:46:42.521125	{"sessionId": "c5b2838d-8d1f-c8da-14ff-44fcb500ac2c"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:46:42.521125
59	RIDER	11	jomana	\N	f08759db-7136-4fc1-a97d-4dafebb0e10e	\N	2026-07-06 21:46:48.44838	{"reason": "Cancelled by rider (stale ride cleanup)"}	RIDE_CANCELLED	f	\N	\N	193	2026-07-06 21:46:48.44838
60	SYSTEM	14	\N	\N	8f1efad0-5d9c-47b1-8dd6-910ce9a1be51	\N	2026-07-06 21:46:53.587471	{"reason": "", "sessionId": "bce14497-b1ac-150c-c429-1bd70930b425"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:46:53.587471
61	SYSTEM	14	\N	\N	1ee0f10d-a5fb-4207-9d3d-2662c082016d	\N	2026-07-06 21:46:54.074977	{"sessionId": "d28faa44-9e2c-4a17-69db-e797a7c7e092"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:46:54.074977
62	RIDER	11	jomana	\N	d5bf2f6e-2848-4f0c-8bb1-68a072b827cf	\N	2026-07-06 21:47:14.712937	{"rideType": "ECONOMY", "estimatedFare": 2.39, "pickupAddress": "KSA-DAM-حي الفردوس-1ب", "dropoffAddress": "KSA-DAM-حي المنتزه-المسك", "estimatedDistance": 1.927, "estimatedDuration": 5}	RIDE_REQUESTED	f	\N	\N	194	2026-07-06 21:47:14.712937
63	DRIVER	14	Mustaasai	\N	c4affc4c-bf31-45db-a49a-b1feee4e29b4	\N	2026-07-06 21:47:17.324242	{"driverId": 14, "driverName": "Mustaasai"}	RIDE_ACCEPTED	f	\N	\N	194	2026-07-06 21:47:17.324242
64	DRIVER	14	Mustaasai	\N	e54d6dc3-2a20-4e2e-b0c8-c87c396ed3cf	\N	2026-07-06 21:47:21.741048	{}	DRIVER_ARRIVED	f	\N	\N	194	2026-07-06 21:47:21.741048
65	SYSTEM	11	\N	\N	6cac00bc-ff62-4bcb-ba85-a472a38ad3e5	\N	2026-07-06 21:47:32.677939	{"reason": "", "sessionId": "c5b2838d-8d1f-c8da-14ff-44fcb500ac2c"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:47:32.677939
66	SYSTEM	11	\N	\N	3469277e-de34-4bce-abb9-54da79786afc	\N	2026-07-06 21:47:38.162512	{"sessionId": "b33f5ca2-ad4f-2ad3-19f0-d2eba78f0af6"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:47:38.162512
67	DRIVER	14	Mustaasai	\N	e37e5476-0685-497d-91b5-02bc73bb7a2f	\N	2026-07-06 21:47:58.681629	{"reason": ""}	RIDE_CANCELLED	f	\N	\N	194	2026-07-06 21:47:58.681629
68	SYSTEM	14	\N	\N	55a041e2-1466-41ba-aed2-d81eb909868c	\N	2026-07-06 21:47:58.953471	{"reason": "", "sessionId": "d28faa44-9e2c-4a17-69db-e797a7c7e092"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:47:58.953471
69	SYSTEM	14	\N	\N	56770fd5-1f63-42e0-a039-ff1439c5b420	\N	2026-07-06 21:47:59.226731	{"sessionId": "2ecdd44a-6d4b-de8d-8fe2-5150e5b41ac6"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:47:59.226731
70	RIDER	6	John Rider	\N	9c1552ca-0632-4470-8ab1-8e49c0b6d48b	\N	2026-07-06 21:48:40.568665	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-06 21:48:40.568665
71	SYSTEM	6	\N	\N	5cb8186f-e900-4a85-b891-1d35389e074f	\N	2026-07-06 21:48:41.888229	{"sessionId": "12c99cd9-0044-e4a8-83ae-c74d1aed58f3"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:48:41.888229
72	RIDER	6	John Rider	\N	6dfe8397-c472-43bb-8d60-3814800947fe	\N	2026-07-06 21:49:00.807206	{"rideType": "ECONOMY", "estimatedFare": 2.59, "pickupAddress": "KSA-الد-حي الفردوس-1ب", "dropoffAddress": "KSA-DAM-Al Muntazah-العناب", "estimatedDistance": 2.925, "estimatedDuration": 6}	RIDE_REQUESTED	f	\N	\N	195	2026-07-06 21:49:00.807206
73	DRIVER	14	Mustaasai	\N	563af431-a917-4df5-9f7d-afdcf5df30a5	\N	2026-07-06 21:49:04.545604	{"driverId": 14, "driverName": "Mustaasai"}	RIDE_ACCEPTED	f	\N	\N	195	2026-07-06 21:49:04.545604
74	SYSTEM	6	\N	\N	9fdf170b-794f-44e5-a402-56c645264904	\N	2026-07-06 21:49:13.297047	{"reason": "", "sessionId": "12c99cd9-0044-e4a8-83ae-c74d1aed58f3"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:49:13.297047
75	SYSTEM	6	\N	\N	c9edec21-fb2f-4177-bc25-bc91b17dde1d	\N	2026-07-06 21:49:18.772101	{"sessionId": "8a1966d2-bf7d-7c51-6bf7-d8d6ed2d8666"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:49:18.772101
76	DRIVER	14	Mustaasai	\N	958bf754-9350-474c-b178-63281b97624d	\N	2026-07-06 21:49:54.770125	{}	DRIVER_ARRIVED	f	\N	\N	195	2026-07-06 21:49:54.770125
77	DRIVER	14	Mustaasai	\N	fe2005db-1ec0-4748-ad91-1ae1749ee386	\N	2026-07-06 21:50:15.738182	{"reason": ""}	RIDE_CANCELLED	f	\N	\N	195	2026-07-06 21:50:15.738182
84	ADMIN	1	\N	\N	2afb1382-cd61-482e-809d-7da6d077aa7e	\N	2026-07-06 21:51:17.413739	{}	ADMIN_VIEWED_RIDE	f	\N	\N	194	2026-07-06 21:51:17.413739
78	SYSTEM	14	\N	\N	9842bc0f-efc7-475c-91cb-72034e136201	\N	2026-07-06 21:50:16.112984	{"reason": "", "sessionId": "2ecdd44a-6d4b-de8d-8fe2-5150e5b41ac6"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:50:16.112984
79	SYSTEM	14	\N	\N	944f01ba-3eb5-49bd-bb72-6480ad53b2ca	\N	2026-07-06 21:50:16.520432	{"sessionId": "b6ea153f-3ac4-79d9-317d-65c59715dd03"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:50:16.520432
80	SYSTEM	14	\N	\N	5b4c1468-d398-4aef-af4d-08c61b9b3e9f	\N	2026-07-06 21:50:25.117291	{"reason": "", "sessionId": "b6ea153f-3ac4-79d9-317d-65c59715dd03"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:50:25.117291
81	ADMIN	1	Mustafa Assi	\N	090904cf-2d07-4688-931c-b3c799acca23	\N	2026-07-06 21:50:40.613161	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-06 21:50:40.613161
82	SYSTEM	1	\N	\N	6dd20871-bafe-472c-9dd9-ff4e5a6c312a	\N	2026-07-06 21:50:41.851727	{"sessionId": "77942404-7dbd-0284-25a8-5774c9b91d3d"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-06 21:50:41.851727
83	ADMIN	1	\N	\N	0e411c24-4f8f-464f-8f89-8b32d5e13a39	\N	2026-07-06 21:50:52.336344	{}	ADMIN_VIEWED_RIDE	f	\N	\N	195	2026-07-06 21:50:52.336344
85	SYSTEM	1	\N	\N	52aaab59-38fe-4241-aa5a-cc0d8ab8c132	\N	2026-07-06 21:51:52.574622	{"reason": "", "sessionId": "77942404-7dbd-0284-25a8-5774c9b91d3d"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:51:52.574622
86	SYSTEM	6	\N	\N	da4d569b-28e0-45d0-92d5-7ab320523137	\N	2026-07-06 21:51:55.940078	{"reason": "", "sessionId": "8a1966d2-bf7d-7c51-6bf7-d8d6ed2d8666"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:51:55.939076
87	SYSTEM	11	\N	\N	5e578213-27d5-4d2a-8d3a-9aed2c92bd88	\N	2026-07-06 21:52:06.594922	{"reason": "", "sessionId": "b33f5ca2-ad4f-2ad3-19f0-d2eba78f0af6"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-06 21:52:06.594922
88	RIDER	6	John Rider	\N	d03b76bf-b571-4c3f-9848-2e257c642a08	\N	2026-07-07 00:06:03.181547	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-07 00:06:03.181547
89	SYSTEM	6	\N	\N	316d5fc4-57c6-4391-8f42-d243aa9175d8	\N	2026-07-07 00:06:04.521466	{"sessionId": "660756a1-783f-eec9-803b-cd8e4f5b17a3"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 00:06:04.521466
90	DRIVER	7	Mike Driver	\N	16a5a92e-ec43-4e0a-881a-44d731dfb97a	\N	2026-07-07 00:06:05.500218	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-07 00:06:05.500218
91	SYSTEM	7	\N	\N	031a9d9b-792c-4b82-9cd7-09719a239caa	\N	2026-07-07 00:06:06.603917	{"sessionId": "411a0097-a134-9bbb-cf1a-fb759e6f15c1"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 00:06:06.603917
92	RIDER	6	John Rider	\N	0b0f1d27-ab45-4d0d-a311-44d1e555ce37	\N	2026-07-07 00:06:44.110325	{"rideType": "LUXURY", "estimatedFare": 8.35, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	196	2026-07-07 00:06:44.110325
93	RIDER	6	John Rider	\N	9f60fed2-cacd-4abc-8d8e-8ee68c552570	\N	2026-07-07 00:06:52.255444	{"reason": "Rider cancelled search"}	RIDE_CANCELLED	f	\N	\N	196	2026-07-07 00:06:52.255444
94	SYSTEM	6	\N	\N	ae3daa74-4eee-409a-93d3-e6222a022e61	\N	2026-07-07 00:06:52.552975	{"reason": "", "sessionId": "660756a1-783f-eec9-803b-cd8e4f5b17a3"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 00:06:52.552975
95	SYSTEM	6	\N	\N	c7cc0d4e-b364-40ae-944b-978cc4c71793	\N	2026-07-07 00:06:52.876396	{"sessionId": "e2783bfe-4e82-24d7-465e-ae42c6bce408"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 00:06:52.876396
96	RIDER	6	John Rider	\N	e235c942-ece9-4543-bf08-c57ec35d0bf8	\N	2026-07-07 00:07:09.222282	{"rideType": "LUXURY", "estimatedFare": 6.17, "pickupAddress": "KSA-الد-حي الفردوس-1ب", "dropoffAddress": "KSA-DAM-Al Firdaws-Salsabil Street", "estimatedDistance": 0.342, "estimatedDuration": 3}	RIDE_REQUESTED	f	\N	\N	197	2026-07-07 00:07:09.222282
97	DRIVER	7	Mike Driver	\N	523ab50b-1ea3-46d9-8cca-b568e958719d	\N	2026-07-07 00:07:17.091702	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	197	2026-07-07 00:07:17.091702
98	SYSTEM	6	\N	\N	eba112c4-9fc6-4597-aaed-781e46eaae4b	\N	2026-07-07 00:07:28.186759	{"reason": "", "sessionId": "e2783bfe-4e82-24d7-465e-ae42c6bce408"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 00:07:28.186759
99	SYSTEM	6	\N	\N	47d86863-f3ff-4614-b545-483720e1465e	\N	2026-07-07 00:07:39.186417	{"sessionId": "9ecf93ab-820d-25b4-208c-cdd74dbc02ef"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 00:07:39.186417
100	DRIVER	7	Mike Driver	\N	c14397de-2fa5-4be3-81a8-386daef66ad4	\N	2026-07-07 00:07:49.003274	{}	DRIVER_ARRIVED	f	\N	\N	197	2026-07-07 00:07:49.003274
101	SYSTEM	6	\N	\N	d82a3271-0f45-4a79-8915-aace555f6eea	\N	2026-07-07 00:08:48.896627	{"reason": "", "sessionId": "9ecf93ab-820d-25b4-208c-cdd74dbc02ef"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 00:08:48.896627
102	SYSTEM	6	\N	\N	c3be2b86-1acc-4489-a033-27910e27626f	\N	2026-07-07 00:08:54.069152	{"sessionId": "1ffc511c-9c6d-4286-a6b0-5d6e4ac9ff2f"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 00:08:54.069152
103	DRIVER	7	Mike Driver	\N	4c3e0967-be3b-4bc9-bde0-c1ecd9f368ba	\N	2026-07-07 00:09:03.748262	{}	RIDE_STARTED	f	\N	\N	197	2026-07-07 00:09:03.748262
104	DRIVER	7	Mike Driver	\N	a0741113-9620-4cd1-9330-a608c60cbe25	\N	2026-07-07 00:09:11.836081	{"finalFare": 6.17}	RIDE_COMPLETED	f	\N	\N	197	2026-07-07 00:09:11.836081
105	RIDER	6	John Rider	\N	abfca069-39a3-4442-9206-1e947aa248e7	\N	2026-07-07 00:09:15.995329	{"amount": 6.17}	PAYMENT_CONFIRMED	f	\N	\N	197	2026-07-07 00:09:15.995329
106	DRIVER	7	Mike Driver	\N	bf4fe067-d2c7-42ac-a6ef-38ae788f5f21	\N	2026-07-07 00:09:20.630422	{"appFee": 0.93, "netAmount": 5.24, "grossAmount": 6.17}	PAYMENT_RECEIVED	f	\N	\N	197	2026-07-07 00:09:20.630422
107	SYSTEM	7	\N	\N	35f11744-1476-421c-aa64-6448d4f89d7d	\N	2026-07-07 00:09:29.948756	{"reason": "", "sessionId": "411a0097-a134-9bbb-cf1a-fb759e6f15c1"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 00:09:29.948756
108	SYSTEM	7	\N	\N	675584a0-0bdc-472c-95a9-9f6802afcf7b	\N	2026-07-07 00:09:30.425457	{"sessionId": "6766d89b-116b-2885-d308-5db53a20195d"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 00:09:30.425457
109	SYSTEM	6	\N	\N	77e44691-b8b5-46ce-a144-4b4b54a5d8c8	\N	2026-07-07 00:09:33.676625	{"reason": "", "sessionId": "1ffc511c-9c6d-4286-a6b0-5d6e4ac9ff2f"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 00:09:33.676625
110	SYSTEM	6	\N	\N	37b4da8f-2adb-46df-a17d-9323ad6e965b	\N	2026-07-07 00:09:33.943355	{"sessionId": "14667d2c-5b35-319b-3a33-cba41488d2dc"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 00:09:33.943355
111	SYSTEM	7	\N	\N	1fe0aba1-86c6-4976-b3a3-95c0ee4b21ac	\N	2026-07-07 00:09:39.860468	{"reason": "", "sessionId": "6766d89b-116b-2885-d308-5db53a20195d"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 00:09:39.860468
112	RIDER	6	John Rider	\N	801850ea-4549-4725-b319-3d3fdf0bc803	\N	2026-07-07 09:57:36.209131	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-07 09:57:36.209131
113	SYSTEM	6	\N	\N	2f31ea60-968e-478c-83e7-d1975580410a	\N	2026-07-07 09:57:37.529462	{"sessionId": "a72cd0d8-4eb7-a361-0f7e-411439c784e2"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 09:57:37.529462
114	DRIVER	7	Mike Driver	\N	234f3bdc-6d70-45eb-bbf7-3718829c6690	\N	2026-07-07 09:58:36.396532	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-07 09:58:36.396532
115	SYSTEM	7	\N	\N	a73d29fb-3bb7-468b-ab08-c283a6ca324c	\N	2026-07-07 09:58:36.70281	{"sessionId": "48293f13-b609-39df-bc50-f22066c71dbd"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 09:58:36.70281
116	RIDER	6	John Rider	\N	6c0c3c42-fdf0-4246-971f-2f628097fd0d	\N	2026-07-07 09:58:45.214374	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	198	2026-07-07 09:58:45.214374
117	DRIVER	7	Mike Driver	\N	e957b8df-f06c-4edf-80ff-22e794b81ef9	\N	2026-07-07 09:58:57.339934	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	198	2026-07-07 09:58:57.339934
120	DRIVER	7	Mike Driver	\N	1ee6d94d-d5fc-4dd2-bdc8-f6514924676a	\N	2026-07-07 09:59:44.700163	{}	DRIVER_ARRIVED	f	\N	\N	198	2026-07-07 09:59:44.700163
123	DRIVER	7	Mike Driver	\N	7d527b06-5bbf-462a-a96d-15ff9ec5d521	\N	2026-07-07 10:00:30.022832	{}	RIDE_STARTED	f	\N	\N	198	2026-07-07 10:00:30.022832
124	DRIVER	7	Mike Driver	\N	2bcc635c-0535-45e0-95fb-02d1e76efabd	\N	2026-07-07 10:01:42.855719	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	198	2026-07-07 10:01:42.855719
125	RIDER	6	John Rider	\N	23f0160c-d53e-45d4-80dc-37c476aef6af	\N	2026-07-07 10:01:52.052362	{"amount": 2.94}	PAYMENT_CONFIRMED	f	\N	\N	198	2026-07-07 10:01:52.052362
132	ADMIN	1	Mustafa Assi	\N	c04ed83d-1aee-4de6-a0ec-4813e2d84578	\N	2026-07-07 10:02:53.627986	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-07 10:02:53.627986
135	RIDER	6	John Rider	\N	fe41f3b2-c718-4bbb-84d7-2c5a7bcf5d5f	\N	2026-07-07 10:09:15.107791	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-07 10:09:15.107791
118	SYSTEM	6	\N	\N	9c30b461-a61f-489b-80d3-fb856817892b	\N	2026-07-07 09:59:10.788132	{"reason": "", "sessionId": "a72cd0d8-4eb7-a361-0f7e-411439c784e2"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 09:59:10.788132
119	SYSTEM	6	\N	\N	dfbe1081-0ac1-49f7-820c-2ce80d5bd3e8	\N	2026-07-07 09:59:18.354977	{"sessionId": "08b9d4b7-c1c7-3570-ee0d-260cdac1285d"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 09:59:18.354977
121	SYSTEM	6	\N	\N	246fa36b-4efd-4d6d-b021-a9afd95b15a6	\N	2026-07-07 09:59:57.785582	{"reason": "", "sessionId": "08b9d4b7-c1c7-3570-ee0d-260cdac1285d"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 09:59:57.785582
122	SYSTEM	6	\N	\N	38854edf-5bea-48f5-825f-a22a6e782d95	\N	2026-07-07 10:00:03.754028	{"sessionId": "c1cdb2af-3c31-bccc-1fe3-f8a6ad5cdfb6"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 10:00:03.754028
126	DRIVER	7	Mike Driver	\N	65715f5f-8a91-4832-994d-786126702ba0	\N	2026-07-07 10:02:03.297525	{"appFee": 0.44, "netAmount": 2.50, "grossAmount": 2.94}	PAYMENT_RECEIVED	f	\N	\N	198	2026-07-07 10:02:03.297525
127	SYSTEM	6	\N	\N	29029a0d-168b-402c-9a7f-225a2916691a	\N	2026-07-07 10:02:12.793693	{"reason": "", "sessionId": "c1cdb2af-3c31-bccc-1fe3-f8a6ad5cdfb6"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 10:02:12.793693
128	SYSTEM	6	\N	\N	52159c94-a7ea-4111-bdb0-3fc0c59701cb	\N	2026-07-07 10:02:13.095397	{"sessionId": "393be89b-e3c5-e9f2-fdf6-dab167e47fde"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 10:02:13.095397
129	SYSTEM	7	\N	\N	43ab3c26-b343-481e-ae4b-8f1195aff82a	\N	2026-07-07 10:02:16.566796	{"reason": "", "sessionId": "48293f13-b609-39df-bc50-f22066c71dbd"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 10:02:16.566796
130	SYSTEM	7	\N	\N	8ceb8ba4-6ecb-441d-8693-2c8faa7402d3	\N	2026-07-07 10:02:16.684784	{"sessionId": "cc3fc990-3acb-7ca5-b5dc-b6b6fa77ebb0"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 10:02:16.684784
131	SYSTEM	6	\N	\N	f152a616-cdcb-4f16-8763-2f9383778ee7	\N	2026-07-07 10:02:26.316344	{"reason": "", "sessionId": "393be89b-e3c5-e9f2-fdf6-dab167e47fde"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 10:02:26.316344
133	SYSTEM	1	\N	\N	f772a7ef-6ce4-4d62-893b-7223fc356c3e	\N	2026-07-07 10:02:54.27968	{"sessionId": "4873b519-9cdb-ebcd-7477-f535f27f66b2"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 10:02:54.27968
134	SYSTEM	1	\N	\N	b9f185bd-f680-4e78-86a3-c9df18728380	\N	2026-07-07 10:04:33.217103	{"reason": "", "sessionId": "4873b519-9cdb-ebcd-7477-f535f27f66b2"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 10:04:33.2161
136	SYSTEM	6	\N	\N	47506ec9-f2a0-4263-a9fd-b29f2331ea33	\N	2026-07-07 10:09:15.749556	{"sessionId": "174013f8-94d2-7ea1-2a12-de8beae48cee"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-07 10:09:15.749556
137	SYSTEM	6	\N	\N	0a60e765-ded2-475c-9dc1-1c2ae27ab45f	\N	2026-07-07 10:10:04.932651	{"reason": "", "sessionId": "174013f8-94d2-7ea1-2a12-de8beae48cee"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 10:10:04.932651
138	SYSTEM	7	\N	\N	bf1410e4-e8a3-4e95-9cc8-d955684a5ac5	\N	2026-07-07 10:36:44.195569	{"reason": "", "sessionId": "cc3fc990-3acb-7ca5-b5dc-b6b6fa77ebb0"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-07 10:36:44.195569
139	RIDER	11	jomana	\N	6c2b2a54-9971-4916-995f-bc98bbd6f941	\N	2026-07-08 18:31:26.01493	{"email": "diarjojo89@gmail.com"}	LOGIN	f	\N	\N	\N	2026-07-08 18:31:26.01493
140	SYSTEM	11	\N	\N	6eef0ce6-020a-4ae1-a686-d814a940233e	\N	2026-07-08 18:31:26.958648	{"sessionId": "7efb619b-cacc-ccb4-864b-0a0dca863d2e"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 18:31:26.958648
141	DRIVER	13	muasi	\N	d2074513-5d5c-47a8-8392-21b0886a88dd	\N	2026-07-08 18:32:25.580323	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-08 18:32:25.580323
142	SYSTEM	13	\N	\N	d7a2e978-95dd-4632-a7f5-a699d52b3bd3	\N	2026-07-08 18:32:27.831817	{"sessionId": "7e68c7a1-8aca-a11a-e9fd-202e04309564"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 18:32:27.831817
143	SYSTEM	13	\N	\N	0e8ee7f2-afae-42d3-aa25-87989b78b85b	\N	2026-07-08 18:32:47.160332	{"reason": "", "sessionId": "7e68c7a1-8aca-a11a-e9fd-202e04309564"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 18:32:47.160332
144	SYSTEM	13	\N	\N	b4cac14d-c902-4f98-8240-e61d1b3f69d3	\N	2026-07-08 18:33:02.608272	{"sessionId": "ae9e12d0-4045-74bd-784c-57f7e28ee26e"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 18:33:02.608272
145	SYSTEM	11	\N	\N	79f3ddf1-19fd-4142-b3e4-43c0cf283669	\N	2026-07-08 18:33:15.612807	{"reason": "", "sessionId": "7efb619b-cacc-ccb4-864b-0a0dca863d2e"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 18:33:15.612807
146	SYSTEM	11	\N	\N	d5b25d77-5b23-46fb-b1f5-d02801fc82fc	\N	2026-07-08 18:33:20.547128	{"sessionId": "528b5994-1340-029c-99af-fbab3ff3193c"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 18:33:20.547128
147	SYSTEM	13	\N	\N	70af2f36-ed4d-4929-abdb-3b592b27df50	\N	2026-07-08 18:34:08.587298	{"reason": "", "sessionId": "ae9e12d0-4045-74bd-784c-57f7e28ee26e"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 18:34:08.587298
148	DRIVER	7	Mike Driver	\N	961adc29-04db-4faa-ab92-9ea7e4b06af9	\N	2026-07-08 18:34:27.617342	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 18:34:27.617342
149	SYSTEM	7	\N	\N	3c87855a-f109-437b-87b1-6fde246303cb	\N	2026-07-08 18:34:33.185643	{"sessionId": "7a1737bb-348f-c00e-91d6-f5daabd02d44"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 18:34:33.185643
150	SYSTEM	7	\N	\N	c9225ee2-75ed-451d-a31b-b69cdb61599f	\N	2026-07-08 18:34:37.962639	{"reason": "", "sessionId": "7a1737bb-348f-c00e-91d6-f5daabd02d44"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 18:34:37.962639
151	DRIVER	13	muasi	\N	2479a201-7539-4cf5-846c-aa0b9d8c3f02	\N	2026-07-08 18:35:36.864647	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-08 18:35:36.864647
152	SYSTEM	13	\N	\N	cff8a41d-f1aa-433a-a933-7a49b86bef58	\N	2026-07-08 18:35:39.908956	{"sessionId": "72513a33-43b6-5dac-1530-7dfa6fddeb13"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 18:35:39.908956
153	RIDER	11	jomana	\N	ff0d74fe-e359-4598-beb1-55e210429077	\N	2026-07-08 18:35:45.835367	{"rideType": "ECONOMY", "estimatedFare": 2.07, "pickupAddress": "26.3787, 50.1214", "dropoffAddress": "26.3763, 50.1193", "estimatedDistance": 0.3373825712745526, "estimatedDuration": 1}	RIDE_REQUESTED	f	\N	\N	199	2026-07-08 18:35:45.835367
154	DRIVER	13	muasi	\N	43c17b40-e919-4ada-a5c1-a22b7f936fec	\N	2026-07-08 18:35:53.294933	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	199	2026-07-08 18:35:53.294933
155	DRIVER	13	muasi	\N	2bf0abea-adfb-458d-b23d-570aea0f2c53	\N	2026-07-08 18:36:06.722378	{}	DRIVER_ARRIVED	f	\N	\N	199	2026-07-08 18:36:06.722378
156	DRIVER	13	muasi	\N	5eb5b1c3-3c01-4ef0-b971-72681f976368	\N	2026-07-08 18:36:17.121491	{}	RIDE_STARTED	f	\N	\N	199	2026-07-08 18:36:17.121491
157	DRIVER	13	muasi	\N	ab7260cd-0935-4b36-a92e-0100ca1b34e4	\N	2026-07-08 18:36:40.748659	{"finalFare": 2.07}	RIDE_COMPLETED	f	\N	\N	199	2026-07-08 18:36:40.748659
158	SYSTEM	11	\N	\N	f38380c9-b5bf-43bf-8f12-8c6839e38d55	\N	2026-07-08 18:37:18.872867	{"reason": "", "sessionId": "528b5994-1340-029c-99af-fbab3ff3193c"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 18:37:18.872867
159	SYSTEM	11	\N	\N	3940d165-f07b-49ca-967f-b84c0a85cc92	\N	2026-07-08 18:37:19.145918	{"sessionId": "7e399a53-f1c8-29bc-20e8-56c1ce9dded5"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 18:37:19.145918
160	SYSTEM	13	\N	\N	260ad96c-4f05-4970-9502-ff86e9b336bf	\N	2026-07-08 18:37:22.787994	{"reason": "", "sessionId": "72513a33-43b6-5dac-1530-7dfa6fddeb13"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 18:37:22.787471
161	SYSTEM	13	\N	\N	adc2a141-fe41-422f-8a18-07b9223ce4ab	\N	2026-07-08 18:37:23.012539	{"sessionId": "c6250d22-e531-8933-076f-95418ddfa5a7"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 18:37:23.012539
162	SYSTEM	13	\N	\N	b981b2ae-e113-4d2c-9d8b-708625fcecbc	\N	2026-07-08 18:37:47.724318	{"reason": "", "sessionId": "c6250d22-e531-8933-076f-95418ddfa5a7"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 18:37:47.724318
163	SYSTEM	11	\N	\N	5b961e81-9733-4aa3-9179-e31cee6224e1	\N	2026-07-08 18:38:01.654934	{"reason": "", "sessionId": "7e399a53-f1c8-29bc-20e8-56c1ce9dded5"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 18:38:01.654934
164	RIDER	6	John Rider	\N	37fafa56-1811-4945-aba7-a30ccf49307e	\N	2026-07-08 20:36:06.383854	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 20:36:06.383854
165	DRIVER	7	Mike Driver	\N	9f0d4385-f42c-476b-8662-303720a13a55	\N	2026-07-08 20:36:06.383854	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 20:36:06.383854
166	SYSTEM	7	\N	\N	bd38b3aa-2a0d-4e2a-872b-e6c1b4d06a2d	\N	2026-07-08 20:36:09.695653	{"sessionId": "074e2172-955d-0199-4816-eaa4aeb69113"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 20:36:09.695653
167	SYSTEM	6	\N	\N	8b3a0b99-401e-4d8f-aa88-b2fa1efbe83a	\N	2026-07-08 20:36:10.60552	{"sessionId": "c92f0523-ca72-6042-cd34-367e77479f8b"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 20:36:10.60552
168	RIDER	6	John Rider	\N	4a8ada71-8308-4e4e-9e1f-2fc9af493975	\N	2026-07-08 20:36:54.885805	{"rideType": "ECONOMY", "estimatedFare": 2.63, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 3.135810457950175, "estimatedDuration": 6}	RIDE_REQUESTED	f	\N	\N	200	2026-07-08 20:36:54.885805
169	DRIVER	7	Mike Driver	\N	cc75a692-7b55-4e96-b6e3-92d444593af1	\N	2026-07-08 20:37:05.743121	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	200	2026-07-08 20:37:05.743121
170	DRIVER	7	Mike Driver	\N	44a29b8f-1b5c-4e73-957b-413b20f941d0	\N	2026-07-08 20:37:19.373829	{}	DRIVER_ARRIVED	f	\N	\N	200	2026-07-08 20:37:19.373829
171	DRIVER	7	Mike Driver	\N	6aaab233-0a26-4846-921c-bf95f58fd403	\N	2026-07-08 20:37:28.262973	{}	RIDE_STARTED	f	\N	\N	200	2026-07-08 20:37:28.262973
172	DRIVER	7	Mike Driver	\N	94a98baa-a834-4cf2-927e-75209b326dea	\N	2026-07-08 20:37:34.95583	{"finalFare": 2.63}	RIDE_COMPLETED	f	\N	\N	200	2026-07-08 20:37:34.95583
173	SYSTEM	6	\N	\N	7ac1dbad-a416-4462-b0bc-fb88ebf30606	\N	2026-07-08 20:40:49.88741	{"reason": "", "sessionId": "c92f0523-ca72-6042-cd34-367e77479f8b"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 20:40:49.88741
174	SYSTEM	6	\N	\N	84547626-e893-4373-8001-33788627b817	\N	2026-07-08 20:40:49.982803	{"sessionId": "72f01258-2d6d-93a2-dd5f-3199136aa32a"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 20:40:49.982803
175	SYSTEM	7	\N	\N	b7539091-57ea-4320-9157-de68352c9a0c	\N	2026-07-08 20:40:56.768073	{"reason": "", "sessionId": "074e2172-955d-0199-4816-eaa4aeb69113"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 20:40:56.768073
176	SYSTEM	7	\N	\N	5ae8bf20-5598-40a5-ae3e-0ca4727c6df5	\N	2026-07-08 20:40:57.325536	{"sessionId": "e1a2adc1-17f0-56c6-e585-7c35e6fa41e5"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 20:40:57.325536
177	SYSTEM	13	\N	\N	6df4d93b-2804-4b4e-95c6-8e950a3183f3	\N	2026-07-08 20:41:11.447961	{"sessionId": "d9ca04b4-8bc1-cb67-70cd-9390b4e843f2"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 20:41:11.447961
178	SYSTEM	13	\N	\N	8a6a226c-4b11-4541-8e97-81e8a3f57154	\N	2026-07-08 20:41:22.517639	{"reason": "", "sessionId": "d9ca04b4-8bc1-cb67-70cd-9390b4e843f2"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 20:41:22.517639
179	ADMIN	1	Mustafa Assi	\N	3d9bcf23-1372-4751-93ac-93faf59eff2d	\N	2026-07-08 20:41:38.316243	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-08 20:41:38.316243
180	SYSTEM	1	\N	\N	11b37190-728f-4fc7-81c4-b78b600454e1	\N	2026-07-08 20:41:39.90473	{"sessionId": "041fbb82-f3fd-761a-c950-4892777131cc"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 20:41:39.90473
181	ADMIN	1	\N	\N	f15588aa-446a-4645-9d85-d3385bf0c091	\N	2026-07-08 20:41:54.46485	{}	ADMIN_VIEWED_RIDE	f	\N	\N	200	2026-07-08 20:41:54.464766
182	ADMIN	1	\N	\N	f443a29b-af9e-4230-ab2c-817cad51cc52	\N	2026-07-08 20:42:39.044584	{}	ADMIN_VIEWED_RIDE	f	\N	\N	200	2026-07-08 20:42:39.044584
183	ADMIN	1	\N	\N	7fde6314-2fd6-41bd-8ff5-afe42fd7940b	\N	2026-07-08 20:42:43.355686	{}	ADMIN_VIEWED_RIDE	f	\N	\N	199	2026-07-08 20:42:43.354687
184	ADMIN	1	\N	\N	43a9a7a7-5e0b-4faf-a64a-9ea6afb39fde	\N	2026-07-08 20:42:46.549595	{}	ADMIN_VIEWED_RIDE	f	\N	\N	197	2026-07-08 20:42:46.549595
185	ADMIN	1	\N	\N	191ab8ff-89bd-4c0c-86e7-e11129440731	\N	2026-07-08 20:42:50.085251	{}	ADMIN_VIEWED_RIDE	f	\N	\N	196	2026-07-08 20:42:50.085251
186	ADMIN	1	\N	\N	6cb7fb1d-dc45-41f8-b3ee-17bda977a91c	\N	2026-07-08 20:43:00.091145	{}	ADMIN_VIEWED_RIDE	f	\N	\N	188	2026-07-08 20:43:00.091145
187	SYSTEM	1	\N	\N	71c7cb4f-dfbc-4939-9d8b-dd50f167da59	\N	2026-07-08 21:02:28.31897	{"reason": "", "sessionId": "041fbb82-f3fd-761a-c950-4892777131cc"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 21:02:28.31897
188	DRIVER	13	muasi	\N	a0766f9a-74f7-40ec-87b2-a3bd3cf9c908	\N	2026-07-08 21:04:45.328727	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-08 21:04:45.32822
189	SYSTEM	13	\N	\N	e6f62407-9fbc-44b6-9438-de605935022a	\N	2026-07-08 21:04:46.09746	{"sessionId": "39e7a8ad-0e53-65d9-e36f-a7e972d89289"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 21:04:46.09746
190	SYSTEM	13	\N	\N	852624c4-5fea-4bb6-81d4-7bed403dd726	\N	2026-07-08 21:05:45.79265	{"reason": "", "sessionId": "39e7a8ad-0e53-65d9-e36f-a7e972d89289"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 21:05:45.79265
191	DRIVER	7	Mike Driver	\N	5e865a74-2174-45c8-8b2e-059943630a01	\N	2026-07-08 23:07:11.329329	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 23:07:11.329329
192	SYSTEM	7	\N	\N	13e95df6-2da3-41d8-b194-8f258005c35c	\N	2026-07-08 23:07:12.977724	{"sessionId": "ee020b63-2571-40ee-096f-947387ae3475"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:07:12.977724
193	RIDER	6	John Rider	\N	804d78d4-08fc-4df1-8844-351562007455	\N	2026-07-08 23:07:33.692802	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 23:07:33.692802
194	SYSTEM	6	\N	\N	9c4215e5-6d44-4c8b-807c-fd225d3b5601	\N	2026-07-08 23:07:35.019536	{"sessionId": "380677ce-9817-8523-bd6a-aa8478db23f3"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:07:35.019536
195	RIDER	6	John Rider	\N	c9ba313c-9d56-42cb-9f0e-3a01bd1dce93	\N	2026-07-08 23:08:14.572677	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	201	2026-07-08 23:08:14.572677
196	DRIVER	7	Mike Driver	\N	d0ed3a6f-72c1-4ef0-8a67-d75bf2d1f41e	\N	2026-07-08 23:08:22.001114	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	201	2026-07-08 23:08:22.001114
197	DRIVER	7	Mike Driver	\N	71ba8855-f8ef-43d8-9bb6-9f97c1e500ad	\N	2026-07-08 23:08:41.551911	{}	DRIVER_ARRIVED	f	\N	\N	201	2026-07-08 23:08:41.551911
198	DRIVER	7	Mike Driver	\N	6db204be-b933-4d1d-9897-7d7381527a6d	\N	2026-07-08 23:08:53.974646	{}	RIDE_STARTED	f	\N	\N	201	2026-07-08 23:08:53.974646
199	DRIVER	7	Mike Driver	\N	a624a40d-3ebb-4c39-9a12-8a7588bb668e	\N	2026-07-08 23:09:05.682875	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	201	2026-07-08 23:09:05.682875
200	SYSTEM	6	\N	\N	20fa43da-9a58-4e61-bc8c-e271b56d0158	\N	2026-07-08 23:09:18.455789	{"reason": "", "sessionId": "380677ce-9817-8523-bd6a-aa8478db23f3"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:09:18.455789
201	SYSTEM	6	\N	\N	66e929cb-f63d-4c6c-994a-a38007044d7f	\N	2026-07-08 23:09:19.634427	{"sessionId": "0ca2ad7f-6fb8-2135-83f4-18bd5450435e"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:09:19.634427
202	SYSTEM	7	\N	\N	eecda2d7-7ea2-4dfc-925b-76c2f33f5494	\N	2026-07-08 23:09:24.934493	{"reason": "", "sessionId": "ee020b63-2571-40ee-096f-947387ae3475"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:09:24.934493
203	SYSTEM	7	\N	\N	53f9e354-9619-485c-9510-40d9982ddea4	\N	2026-07-08 23:09:25.13351	{"sessionId": "809d4b37-a08f-78b4-8d10-06e0bfd2a855"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:09:25.13351
204	SYSTEM	7	\N	\N	3761457b-36a5-42ee-82ed-41d49140d707	\N	2026-07-08 23:21:14.053662	{"reason": "", "sessionId": "809d4b37-a08f-78b4-8d10-06e0bfd2a855"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:21:14.053662
205	DRIVER	7	Mike Driver	\N	a2222511-0302-4d93-9ea3-89ab8ec4e0cf	\N	2026-07-08 23:32:37.192245	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 23:32:37.192245
206	RIDER	6	John Rider	\N	de98f82d-5d28-4a8f-a21a-6ca6ce0f1c65	\N	2026-07-08 23:32:37.357131	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 23:32:37.357131
207	SYSTEM	6	\N	\N	97472446-24dd-4aa3-924f-fac4a14866ad	\N	2026-07-08 23:32:38.979599	{"sessionId": "7b779994-5e50-49ec-55df-89e7deede9d9"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:32:38.979599
208	SYSTEM	7	\N	\N	a07c49d8-1115-4ce1-a384-dbcb6db25e1f	\N	2026-07-08 23:32:39.058825	{"sessionId": "61eddf2c-6f26-990d-3802-54be4ae758ae"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:32:39.058825
209	RIDER	6	John Rider	\N	ee533885-b68d-44f9-86fb-e80ec2011952	\N	2026-07-08 23:33:10.395372	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	202	2026-07-08 23:33:10.395372
210	DRIVER	7	Mike Driver	\N	8d52e70f-d3e5-4d43-aa4d-2aed3dd361e9	\N	2026-07-08 23:33:21.860677	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	202	2026-07-08 23:33:21.860677
211	DRIVER	7	Mike Driver	\N	df94495c-d149-4350-bb01-c3368adb4443	\N	2026-07-08 23:33:28.582723	{}	DRIVER_ARRIVED	f	\N	\N	202	2026-07-08 23:33:28.582215
212	DRIVER	7	Mike Driver	\N	f95eadfe-a97c-45b5-8b72-9e2e4be13797	\N	2026-07-08 23:33:36.948199	{}	RIDE_STARTED	f	\N	\N	202	2026-07-08 23:33:36.948199
213	DRIVER	7	Mike Driver	\N	25d4c3b2-3ed3-402f-94a7-ed7175595d1e	\N	2026-07-08 23:33:53.851642	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	202	2026-07-08 23:33:53.851642
214	SYSTEM	7	\N	\N	9e1610b5-1c61-47ca-93fa-631177f83f49	\N	2026-07-08 23:34:45.558813	{"reason": "", "sessionId": "61eddf2c-6f26-990d-3802-54be4ae758ae"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:34:45.558813
215	SYSTEM	7	\N	\N	88937155-e39c-4aac-be16-df90f1ed6572	\N	2026-07-08 23:34:46.718996	{"sessionId": "c2dcb927-e974-9873-ff85-492e8410165b"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:34:46.718996
216	SYSTEM	6	\N	\N	c8088670-9d8b-4017-8cc2-2a263d812cb4	\N	2026-07-08 23:34:52.382005	{"reason": "", "sessionId": "7b779994-5e50-49ec-55df-89e7deede9d9"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:34:52.382005
217	SYSTEM	6	\N	\N	72e5eddd-9520-4c6c-af1b-9518d8c59665	\N	2026-07-08 23:34:52.899038	{"sessionId": "374a1135-d9c3-e166-91e3-40e3c637ade4"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:34:52.899038
218	RIDER	6	John Rider	\N	deab990c-a332-4549-b0f4-e91302db6eef	\N	2026-07-08 23:35:46.399214	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	203	2026-07-08 23:35:46.399214
219	DRIVER	7	Mike Driver	\N	6a4bbc3e-d2e1-4c6e-8c9b-fa429e6cf4bf	\N	2026-07-08 23:35:53.701946	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	203	2026-07-08 23:35:53.701946
220	SYSTEM	6	\N	\N	841e7390-2248-4f34-a04e-1cfe68209ed3	\N	2026-07-08 23:36:26.581874	{"reason": "", "sessionId": "374a1135-d9c3-e166-91e3-40e3c637ade4"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:36:26.581874
221	SYSTEM	7	\N	\N	8fca6690-44a2-4ec2-bb9e-ba5875cc689f	\N	2026-07-08 23:36:33.234245	{"reason": "", "sessionId": "c2dcb927-e974-9873-ff85-492e8410165b"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:36:33.234245
223	DRIVER	7	Mike Driver	\N	99547a77-4be8-4cd0-b4d8-3cecac0135de	\N	2026-07-08 23:55:18.132576	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 23:55:18.132576
222	RIDER	6	John Rider	\N	9a0ac1ad-3be1-49cb-bf2b-3c4b65ce45ba	\N	2026-07-08 23:55:18.132576	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-08 23:55:18.132576
224	SYSTEM	7	\N	\N	23e6b555-aa88-46c1-bebb-8d571d3a7a09	\N	2026-07-08 23:55:20.664161	{"sessionId": "0aa2f9c5-78f3-be1e-1492-7e78d1854836"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:55:20.664161
225	SYSTEM	6	\N	\N	965cc026-e4df-4606-b3a2-93f640a11a0b	\N	2026-07-08 23:55:20.722987	{"sessionId": "6036cdc6-40ac-9300-d40e-0c7cba8d8d9e"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:55:20.722987
226	RIDER	6	John Rider	\N	6041a04a-3bce-427c-9286-777a1acc001e	\N	2026-07-08 23:55:29.359712	{"reason": "Cancelled by rider (stale ride cleanup)"}	RIDE_CANCELLED	f	\N	\N	203	2026-07-08 23:55:29.359712
227	SYSTEM	6	\N	\N	14e75cf6-82a4-4106-b241-17a8f328dc05	\N	2026-07-08 23:55:54.708295	{"sessionId": "90312768-2d99-e599-8d36-ebd003022cf9"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:55:54.708295
228	RIDER	6	John Rider	\N	6e15f096-421a-4218-bbb4-acc1f77c8ca1	\N	2026-07-08 23:56:09.775019	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	204	2026-07-08 23:56:09.775019
229	DRIVER	7	Mike Driver	\N	598a538d-ef7e-46a2-8620-c96d24c232d1	\N	2026-07-08 23:56:21.950565	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	204	2026-07-08 23:56:21.950565
230	DRIVER	7	Mike Driver	\N	3c74f955-747b-47ed-903d-7e4ee940798a	\N	2026-07-08 23:56:27.939405	{}	DRIVER_ARRIVED	f	\N	\N	204	2026-07-08 23:56:27.939405
231	DRIVER	7	Mike Driver	\N	efdaa4eb-9c75-4b27-8235-7d61f1db74e6	\N	2026-07-08 23:56:34.850668	{}	RIDE_STARTED	f	\N	\N	204	2026-07-08 23:56:34.850668
232	DRIVER	7	Mike Driver	\N	7ab7eedb-0940-4258-abda-ce0b5ce2d398	\N	2026-07-08 23:56:41.044226	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	204	2026-07-08 23:56:41.044226
233	DRIVER	7	Mike Driver	\N	b22132f5-40f6-4553-812e-33585b238e2b	\N	2026-07-08 23:57:03.669215	{"reason": "Customer did not pay cash"}	CASH_UNPAID	f	\N	\N	204	2026-07-08 23:57:03.669215
234	SYSTEM	7	\N	\N	1a34a223-ee33-4ece-96a8-2bfe274896f7	\N	2026-07-08 23:57:10.567675	{"reason": "", "sessionId": "0aa2f9c5-78f3-be1e-1492-7e78d1854836"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:57:10.567675
235	SYSTEM	7	\N	\N	1e39e9b3-9898-4c4e-9a6d-389c7edde8e3	\N	2026-07-08 23:57:11.792398	{"sessionId": "3ccacf32-390b-cc57-8346-345694629ff0"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:57:11.792398
236	SYSTEM	6	\N	\N	becfad83-f42f-44ae-b07d-1fcbc3129953	\N	2026-07-08 23:57:23.041066	{"reason": "", "sessionId": "90312768-2d99-e599-8d36-ebd003022cf9"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:57:23.041066
237	SYSTEM	6	\N	\N	89f508a8-a621-4193-af4e-9258d8a7b2b7	\N	2026-07-08 23:57:23.631237	{"sessionId": "9436809f-030a-4baa-67d1-cbe43283349c"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:57:23.631237
238	RIDER	6	John Rider	\N	1d458bca-706d-433b-b5c8-805eae793aff	\N	2026-07-08 23:58:05.259141	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	205	2026-07-08 23:58:05.259141
239	RIDER	6	John Rider	\N	7672db1b-910f-419c-9621-e40560006bf5	\N	2026-07-08 23:59:49.272982	{"reason": "Rider cancelled search"}	RIDE_CANCELLED	f	\N	\N	205	2026-07-08 23:59:49.272982
240	SYSTEM	6	\N	\N	4188bc13-f12a-4cff-9f21-f623f21994e5	\N	2026-07-08 23:59:49.647903	{"reason": "", "sessionId": "9436809f-030a-4baa-67d1-cbe43283349c"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-08 23:59:49.647903
241	SYSTEM	6	\N	\N	6853815d-d7d7-4d12-b2aa-ab106334a310	\N	2026-07-08 23:59:49.916604	{"sessionId": "e70fcfd9-d2b1-e088-0e5f-bbe528433175"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-08 23:59:49.916604
242	SYSTEM	7	\N	\N	e665bca6-9fcc-4bf0-83d6-474a87a61c20	\N	2026-07-09 00:02:28.456726	{"reason": "", "sessionId": "3ccacf32-390b-cc57-8346-345694629ff0"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 00:02:28.456726
243	SYSTEM	6	\N	\N	ee3c571f-af0e-4893-8f5e-9967f62dadcd	\N	2026-07-09 00:02:33.22811	{"reason": "", "sessionId": "e70fcfd9-d2b1-e088-0e5f-bbe528433175"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 00:02:33.22811
244	DRIVER	7	Mike Driver	\N	def89aec-a98b-4408-8739-70e81fa2e128	\N	2026-07-09 00:03:02.554846	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-09 00:03:02.553848
245	RIDER	6	John Rider	\N	a82e4a3d-d855-41ac-9894-4d1b5db3ef1d	\N	2026-07-09 00:03:03.529985	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-09 00:03:03.529985
246	SYSTEM	7	\N	\N	deed7910-7678-415a-aaf8-4f4bee81ca5d	\N	2026-07-09 00:03:03.627519	{"sessionId": "7ddb4654-daed-7bba-62d3-4750229bcd27"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 00:03:03.627519
247	SYSTEM	6	\N	\N	7130b6d8-3652-42d8-acad-fc5a95911a68	\N	2026-07-09 00:03:04.395491	{"sessionId": "a3cc1b0b-be12-aecb-9dd0-92f75b25153f"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 00:03:04.395491
248	RIDER	6	John Rider	\N	8f719160-4af5-47bd-ae93-c76504a6629e	\N	2026-07-09 00:03:28.292689	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	206	2026-07-09 00:03:28.292689
249	DRIVER	7	Mike Driver	\N	ed657d90-76a8-46d8-a800-a4879aede4ed	\N	2026-07-09 00:03:42.115268	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	206	2026-07-09 00:03:42.115268
250	DRIVER	7	Mike Driver	\N	12677d9b-33ab-4544-abf2-26e6ff2e7a41	\N	2026-07-09 00:03:47.508187	{}	DRIVER_ARRIVED	f	\N	\N	206	2026-07-09 00:03:47.508187
251	DRIVER	7	Mike Driver	\N	14658527-dde7-411b-a7b7-901099766938	\N	2026-07-09 00:03:54.957161	{}	RIDE_STARTED	f	\N	\N	206	2026-07-09 00:03:54.957161
252	DRIVER	7	Mike Driver	\N	fa9e88d1-256b-4ee0-b3a7-c227737f1092	\N	2026-07-09 00:04:02.054726	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	206	2026-07-09 00:04:02.053723
253	DRIVER	7	Mike Driver	\N	19e3428b-2cb5-44de-9c9c-65d522953e02	\N	2026-07-09 00:04:19.463208	{"appFee": 0.44, "netAmount": 2.50, "grossAmount": 2.94}	CASH_RECEIVED	f	\N	\N	206	2026-07-09 00:04:19.463208
254	SYSTEM	7	\N	\N	5a0ef950-163e-47ca-8f92-67d01d2ad1f5	\N	2026-07-09 00:04:26.070262	{"reason": "", "sessionId": "7ddb4654-daed-7bba-62d3-4750229bcd27"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 00:04:26.070262
255	SYSTEM	7	\N	\N	94fdd6f2-28ab-406b-bc2f-29d7654c609d	\N	2026-07-09 00:04:26.108118	{"sessionId": "0614b30c-561d-fdba-b388-b3a2fa839662"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 00:04:26.108118
256	SYSTEM	6	\N	\N	89482992-7933-43fa-8890-c294f2358d69	\N	2026-07-09 00:04:28.639773	{"reason": "", "sessionId": "a3cc1b0b-be12-aecb-9dd0-92f75b25153f"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 00:04:28.639705
257	SYSTEM	6	\N	\N	cf5cfb06-f58c-4145-a4ba-dc7acfdf6dce	\N	2026-07-09 00:04:28.99588	{"sessionId": "44507f6f-b199-54d5-0fb2-06c8b949389b"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 00:04:28.99588
258	ADMIN	1	Mustafa Assi	\N	e61065f4-33db-468e-b64f-48c877fed1d6	\N	2026-07-09 00:04:57.57015	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-09 00:04:57.57015
259	SYSTEM	1	\N	\N	6e830142-7c34-4e25-b668-82f9ea3acc77	\N	2026-07-09 00:04:58.196743	{"sessionId": "c0f3da98-5d76-efcf-8293-3c64c848e11f"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 00:04:58.196743
260	ADMIN	1	\N	\N	ab28f151-2a50-40af-b654-1cc0e4ea338c	\N	2026-07-09 00:05:12.562596	{}	ADMIN_VIEWED_RIDE	f	\N	\N	206	2026-07-09 00:05:12.562596
261	ADMIN	1	\N	\N	5a24e6fe-22ac-4964-8523-457f7d0451e0	\N	2026-07-09 00:05:23.481333	{"note": "good"}	ADMIN_NOTE	f	\N	\N	206	2026-07-09 00:05:23.481333
262	ADMIN	1	\N	\N	c33340a9-8180-4860-9b0c-60f9d7d231e7	\N	2026-07-09 00:05:59.407795	{}	ADMIN_VIEWED_RIDE	f	\N	\N	206	2026-07-09 00:05:59.407795
263	ADMIN	1	\N	\N	138a18de-f0e4-409a-8d8e-bd07abc42b96	\N	2026-07-09 00:06:06.653008	{}	ADMIN_VIEWED_RIDE	f	\N	\N	205	2026-07-09 00:06:06.653008
264	ADMIN	1	\N	\N	ab15d3d1-8c42-42b1-a39b-6f6ceebe37a7	\N	2026-07-09 00:07:19.131869	{"driverId": 7}	ADMIN_VIEWED_DRIVER	f	\N	\N	\N	2026-07-09 00:07:19.131869
265	ADMIN	1	\N	\N	47b9e0bd-1c17-4501-9655-b7c4627b01d0	\N	2026-07-09 00:07:27.951474	{"driverId": 13}	ADMIN_VIEWED_DRIVER	f	\N	\N	\N	2026-07-09 00:07:27.951474
266	ADMIN	1	\N	\N	037bc2ab-b13a-4daa-9566-c4ea0f94e55f	\N	2026-07-09 00:07:30.806858	{"driverId": 14}	ADMIN_VIEWED_DRIVER	f	\N	\N	\N	2026-07-09 00:07:30.806858
267	SYSTEM	1	\N	\N	ffc886dc-64b2-44d1-83be-89a154b07fc5	\N	2026-07-09 00:07:49.035051	{"reason": "", "sessionId": "c0f3da98-5d76-efcf-8293-3c64c848e11f"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 00:07:49.035051
268	SYSTEM	7	\N	\N	44b4f0f2-3811-4a2f-a487-51dd5b756ec6	\N	2026-07-09 00:08:01.536522	{"reason": "", "sessionId": "0614b30c-561d-fdba-b388-b3a2fa839662"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 00:08:01.536522
269	SYSTEM	6	\N	\N	135921bd-62cb-4bb2-9271-bebdd09d188f	\N	2026-07-09 00:08:02.461289	{"reason": "", "sessionId": "44507f6f-b199-54d5-0fb2-06c8b949389b"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 00:08:02.461289
270	DRIVER	7	Mike Driver	\N	1e0a700b-bd57-444d-a51f-bd4856a14f2c	\N	2026-07-09 15:45:45.486155	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-09 15:45:45.486155
271	SYSTEM	7	\N	\N	25095f5f-c017-40d9-957a-d6836522f3f3	\N	2026-07-09 15:45:46.777873	{"sessionId": "5b200c49-ba23-f082-3793-000ebbc70d6f"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:45:46.777873
272	RIDER	6	John Rider	\N	4f08eda6-2664-45e9-8217-4e2549ce1930	\N	2026-07-09 15:47:31.546763	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-09 15:47:31.546763
273	SYSTEM	6	\N	\N	97e7c55f-d0fb-4f16-b68e-928248b29df3	\N	2026-07-09 15:47:32.414807	{"sessionId": "406318ac-d119-aa9b-079a-5fe0f0181a54"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:47:32.414807
274	RIDER	6	John Rider	\N	2885d99e-6c70-45ea-a2cf-3a5a5fbb7fef	\N	2026-07-09 15:47:48.073627	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	207	2026-07-09 15:47:48.073627
275	DRIVER	7	Mike Driver	\N	5af9d4a5-5eb8-4bbd-8294-7c52b71a0dad	\N	2026-07-09 15:47:58.042146	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	207	2026-07-09 15:47:58.042146
276	DRIVER	7	Mike Driver	\N	c6a8ae24-66d5-4e1e-bb41-3eaa8ed0075a	\N	2026-07-09 15:49:23.621488	{}	DRIVER_ARRIVED	f	\N	\N	207	2026-07-09 15:49:23.621488
277	DRIVER	7	Mike Driver	\N	509499ce-4a1a-41a3-9b3b-d2739b9ff478	\N	2026-07-09 15:49:56.485665	{}	RIDE_STARTED	f	\N	\N	207	2026-07-09 15:49:56.485665
278	DRIVER	7	Mike Driver	\N	f5ca106a-568d-482c-85c5-e9ebec56bc24	\N	2026-07-09 15:50:08.205114	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	207	2026-07-09 15:50:08.205114
279	SYSTEM	6	\N	\N	0987489d-ff2d-4d75-b0ef-30f115961463	\N	2026-07-09 15:50:36.726962	{"reason": "", "sessionId": "406318ac-d119-aa9b-079a-5fe0f0181a54"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:50:36.725959
280	SYSTEM	6	\N	\N	d9a6216e-93d6-4ebf-9454-722c5bceb548	\N	2026-07-09 15:50:36.861376	{"sessionId": "092d5b61-ce7c-90cd-deb0-753df5fd8f88"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:50:36.861376
281	SYSTEM	7	\N	\N	0881627e-df8c-4b16-b81c-06a9592e9295	\N	2026-07-09 15:50:51.227553	{"reason": "", "sessionId": "5b200c49-ba23-f082-3793-000ebbc70d6f"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:50:51.227553
282	SYSTEM	7	\N	\N	187368c9-7d95-47db-9b2d-de201c95ebbb	\N	2026-07-09 15:50:51.534042	{"sessionId": "1e6b5094-fa5b-a74a-75cb-d2bf2926ba64"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:50:51.534042
283	RIDER	6	John Rider	\N	e260cdc4-e968-4a9c-84de-e4fea949108f	\N	2026-07-09 15:51:17.454422	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	208	2026-07-09 15:51:17.454422
285	DRIVER	7	Mike Driver	\N	1635d167-942d-40b6-9f00-33763fdd9a6d	\N	2026-07-09 15:51:35.863251	{}	DRIVER_ARRIVED	f	\N	\N	208	2026-07-09 15:51:35.863251
284	DRIVER	7	Mike Driver	\N	9e0c58d3-9e0d-478c-8ffd-ae665f3198ea	\N	2026-07-09 15:51:31.435206	{"driverId": 7, "driverName": "Mike Driver"}	RIDE_ACCEPTED	f	\N	\N	208	2026-07-09 15:51:31.435206
287	DRIVER	7	Mike Driver	\N	34c49135-c8b5-4769-82a3-b5d40818b7bb	\N	2026-07-09 15:51:55.230979	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	208	2026-07-09 15:51:55.230979
288	SYSTEM	7	\N	\N	c8399d72-8b2a-4f8b-99ca-a726925a7b45	\N	2026-07-09 15:52:11.14692	{"reason": "", "sessionId": "1e6b5094-fa5b-a74a-75cb-d2bf2926ba64"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:52:11.14692
290	SYSTEM	6	\N	\N	15f45e4c-9ef2-4256-b7c3-5131941ad915	\N	2026-07-09 15:52:26.345718	{"reason": "", "sessionId": "092d5b61-ce7c-90cd-deb0-753df5fd8f88"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:52:26.343715
291	SYSTEM	6	\N	\N	583d043b-7716-45e6-8543-6787bb55fffd	\N	2026-07-09 15:52:26.511898	{"sessionId": "dc3b374f-09a0-cc38-8a8b-868b62df2991"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:52:26.511898
292	DRIVER	13	muasi	\N	91fe2355-9d66-47f3-a3f4-1e5398632aaa	\N	2026-07-09 15:55:10.549274	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-09 15:55:10.549274
293	SYSTEM	13	\N	\N	5a0f98e1-2a41-4c97-9c31-77823cabcd8e	\N	2026-07-09 15:55:10.930069	{"sessionId": "51d51b69-fc98-7781-07f3-f131c9c457c9"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:55:10.930069
294	RIDER	6	John Rider	\N	84a599d9-1eab-4b00-8ac3-7b1adefdef16	\N	2026-07-09 15:55:30.45267	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	209	2026-07-09 15:55:30.45267
295	DRIVER	13	muasi	\N	0dea0628-00bb-4ecf-8164-933bcb76904e	\N	2026-07-09 15:55:38.55175	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	209	2026-07-09 15:55:38.55175
296	SYSTEM	7	\N	\N	8a817637-fd2b-412b-84e8-fa986b336704	\N	2026-07-09 15:55:49.120972	{"reason": "", "sessionId": "89ceb945-35d8-7d0e-9271-20a7a34b95e2"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:55:49.120972
298	DRIVER	13	muasi	\N	78b3f97a-33f6-4df9-aa52-42f615e650be	\N	2026-07-09 15:55:55.693836	{}	RIDE_STARTED	f	\N	\N	209	2026-07-09 15:55:55.693836
299	DRIVER	13	muasi	\N	5afdfe90-c7c2-4b9a-a1a8-c9b8d0589bba	\N	2026-07-09 15:55:57.703257	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	209	2026-07-09 15:55:57.703257
301	SYSTEM	13	\N	\N	82392fb8-6bd8-4347-8c2e-528c4c9a8a04	\N	2026-07-09 15:56:50.548232	{"reason": "", "sessionId": "51d51b69-fc98-7781-07f3-f131c9c457c9"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:56:50.548232
302	SYSTEM	13	\N	\N	8107cb0b-0890-44f8-a7a4-34542d25c464	\N	2026-07-09 15:56:50.668477	{"sessionId": "33038716-254a-f0b0-0bcc-2cd249d0dded"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:56:50.668477
303	SYSTEM	6	\N	\N	e6797cfa-7b7d-4244-9db6-d3beaa49ea73	\N	2026-07-09 15:56:55.961036	{"reason": "", "sessionId": "dc3b374f-09a0-cc38-8a8b-868b62df2991"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:56:55.961036
304	SYSTEM	6	\N	\N	8a5e0503-5ceb-42fb-9280-b3c2dff9fa8a	\N	2026-07-09 15:56:56.1982	{"sessionId": "7d1e5b8a-01dc-bb41-34ea-34f05ffdcde6"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:56:56.1982
308	SYSTEM	13	\N	\N	c0669321-0456-4a5f-9dc1-b5e6fa4b38c4	\N	2026-07-09 15:59:35.444018	{"reason": "", "sessionId": "33038716-254a-f0b0-0bcc-2cd249d0dded"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:59:35.444018
309	SYSTEM	13	\N	\N	c969ae9d-66d7-4af2-b20f-ab97f63093bc	\N	2026-07-09 15:59:35.66607	{"sessionId": "c0a121f5-86c1-b858-41c6-3cdec18f3a26"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:59:35.66607
310	SYSTEM	6	\N	\N	fcf21030-8792-4d3c-a7e5-9dd5517aec85	\N	2026-07-09 15:59:40.061469	{"reason": "", "sessionId": "7d1e5b8a-01dc-bb41-34ea-34f05ffdcde6"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 15:59:40.061469
311	SYSTEM	6	\N	\N	d73022cb-c277-42c1-8675-28ed022c0262	\N	2026-07-09 15:59:40.268343	{"sessionId": "490487c2-795e-ed76-d4c7-8748d393f717"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:59:40.268343
312	DRIVER	13	muasi	\N	678ef581-ff10-49f3-a7ff-5c13c7236f9c	\N	2026-07-09 16:00:04.376363	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-09 16:00:04.376363
313	SYSTEM	13	\N	\N	b858e8c6-2ec5-4b1f-b15b-b941d99a6725	\N	2026-07-09 16:00:05.718183	{"sessionId": "82a3160b-fc3e-6a9a-79e7-1a0860720f5c"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 16:00:05.718183
315	RIDER	6	John Rider	\N	ba41adfd-3134-40e1-8d8a-0f8a94e644ec	\N	2026-07-09 16:00:17.605631	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	211	2026-07-09 16:00:17.605631
319	DRIVER	13	muasi	\N	ed18f065-21f5-4862-8e1a-75adb999a734	\N	2026-07-09 16:00:40.515965	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	211	2026-07-09 16:00:40.515965
321	SYSTEM	13	\N	\N	66670207-77eb-42a3-abde-d6f4c8313db8	\N	2026-07-09 16:01:03.63727	{"reason": "", "sessionId": "82a3160b-fc3e-6a9a-79e7-1a0860720f5c"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 16:01:03.63727
323	SYSTEM	13	\N	\N	baedf6c7-01d5-4c8b-a768-af8a499616e6	\N	2026-07-09 16:01:13.748126	{"reason": "", "sessionId": "985e8176-6ab4-5fb9-e6ec-4661868b40fa"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 16:01:13.748126
324	SYSTEM	6	\N	\N	744b0441-b3ed-4dfb-8c90-3a850a22e6fd	\N	2026-07-09 16:01:13.756274	{"reason": "Connection reset", "sessionId": "490487c2-795e-ed76-d4c7-8748d393f717"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 16:01:13.756274
286	DRIVER	7	Mike Driver	\N	885e7c17-9e74-4771-ba77-a2bb2a16a037	\N	2026-07-09 15:51:45.3523	{}	RIDE_STARTED	f	\N	\N	208	2026-07-09 15:51:45.3523
289	SYSTEM	7	\N	\N	641adfa1-f6cb-485c-b896-d6a3f823c0be	\N	2026-07-09 15:52:15.399931	{"sessionId": "89ceb945-35d8-7d0e-9271-20a7a34b95e2"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 15:52:15.399931
297	DRIVER	13	muasi	\N	ee20c69d-4036-4f1d-9875-2e5ef8f29a0d	\N	2026-07-09 15:55:53.035406	{}	DRIVER_ARRIVED	f	\N	\N	209	2026-07-09 15:55:53.035406
300	DRIVER	13	muasi	\N	05b4dd01-31c9-47c4-a609-61090690a9d3	\N	2026-07-09 15:56:10.444573	{"appFee": 0.44, "netAmount": 2.50, "grossAmount": 2.94}	CASH_RECEIVED	f	\N	\N	209	2026-07-09 15:56:10.444573
305	RIDER	6	John Rider	\N	f59b8b17-88e2-4890-b88a-408bc057ec3f	\N	2026-07-09 15:59:15.514157	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "KSA-DAM-Hajar-Al Iqtisad", "dropoffAddress": "KSA-DAM-حي الشفاء-مكه المكرمه", "estimatedDistance": 4.692, "estimatedDuration": 8}	RIDE_REQUESTED	f	\N	\N	210	2026-07-09 15:59:15.514157
306	DRIVER	13	muasi	\N	2e91450c-f577-4a5c-868d-849de827836e	\N	2026-07-09 15:59:24.306984	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	210	2026-07-09 15:59:24.306984
307	DRIVER	13	muasi	\N	32e77bc0-8055-4d6a-b219-53d5319790e9	\N	2026-07-09 15:59:35.280677	{"reason": "testing"}	RIDE_CANCELLED	f	\N	\N	210	2026-07-09 15:59:35.280677
314	SYSTEM	13	\N	\N	d293a2dd-a54b-4897-903d-47a735311cf4	\N	2026-07-09 16:00:06.065618	{"reason": "", "sessionId": "c0a121f5-86c1-b858-41c6-3cdec18f3a26"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 16:00:06.065618
316	DRIVER	13	muasi	\N	b825bbaa-45e2-4a75-84b3-62ec89efdca3	\N	2026-07-09 16:00:22.069187	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	211	2026-07-09 16:00:22.069187
317	DRIVER	13	muasi	\N	008939ba-767b-439d-9311-c50e6bb21fab	\N	2026-07-09 16:00:28.358382	{}	DRIVER_ARRIVED	f	\N	\N	211	2026-07-09 16:00:28.358382
318	DRIVER	13	muasi	\N	850e7ad0-5f68-48ef-9f57-7cbb2a603344	\N	2026-07-09 16:00:34.903113	{}	RIDE_STARTED	f	\N	\N	211	2026-07-09 16:00:34.903113
320	DRIVER	13	muasi	\N	7f0d8410-2f02-484c-abc5-92d028d88dcb	\N	2026-07-09 16:00:49.61602	{"appFee": 0.44, "netAmount": 2.50, "grossAmount": 2.94}	CASH_RECEIVED	f	\N	\N	211	2026-07-09 16:00:49.61602
322	SYSTEM	13	\N	\N	fcba0f0b-ee1a-4c0e-b0cf-b1eec5553e9c	\N	2026-07-09 16:01:04.258228	{"sessionId": "985e8176-6ab4-5fb9-e6ec-4661868b40fa"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 16:01:04.258228
325	SYSTEM	13	\N	\N	6af163c4-07a8-4fbc-888a-314ed9b45178	\N	2026-07-09 21:13:50.408894	{"sessionId": "5c058fd8-9bbc-0cb4-ee54-2eca1c099c5a"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:13:50.408894
326	SYSTEM	13	\N	\N	a25ec53f-5ab5-490a-bc0a-ec42968d6348	\N	2026-07-09 21:13:59.576857	{"reason": "", "sessionId": "5c058fd8-9bbc-0cb4-ee54-2eca1c099c5a"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:13:59.576857
327	DRIVER	13	muasi	\N	5347da84-b106-46be-8c86-96d013c2b84a	\N	2026-07-09 21:14:40.28679	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-09 21:14:40.28679
328	SYSTEM	13	\N	\N	de508470-a9a0-4cb8-a0ea-14d2e4ea5d9e	\N	2026-07-09 21:14:41.59761	{"sessionId": "5084eb15-f71e-0d05-191f-ebaaef5c1b70"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:14:41.59761
329	SYSTEM	13	\N	\N	a4e4d13e-57f7-4a69-9f98-423d2548ad92	\N	2026-07-09 21:15:08.713998	{"reason": "", "sessionId": "5084eb15-f71e-0d05-191f-ebaaef5c1b70"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:15:08.713998
330	DRIVER	13	muasi	\N	b875aa15-dc46-44aa-9614-c85024c7d588	\N	2026-07-09 21:30:34.65486	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-09 21:30:34.65486
331	SYSTEM	13	\N	\N	98d7f6d9-3e96-4d58-b253-7ed969ac479f	\N	2026-07-09 21:30:36.919568	{"sessionId": "56c2484b-69e5-8565-f351-c204e70e4b48"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:30:36.919568
332	SYSTEM	13	\N	\N	c2379d54-5c6f-4d2f-9640-53a25c20f5bd	\N	2026-07-09 21:30:57.11312	{"reason": "", "sessionId": "56c2484b-69e5-8565-f351-c204e70e4b48"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:30:57.11312
333	RIDER	11	jomana	\N	ed3e5446-0948-49c0-8114-4b774cb42481	\N	2026-07-09 21:31:22.20816	{"email": "diarjojo89@gmail.com"}	LOGIN	f	\N	\N	\N	2026-07-09 21:31:22.20816
334	SYSTEM	11	\N	\N	a73855bf-92cc-44ec-b3b1-3d25989a1583	\N	2026-07-09 21:31:22.928865	{"sessionId": "0de2028e-0cf8-b954-2ad8-d59419d99cbf"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:31:22.928865
335	SYSTEM	11	\N	\N	d81f345c-82fa-4084-9924-b7fd0d5d7ae6	\N	2026-07-09 21:31:31.712783	{"reason": "", "sessionId": "0de2028e-0cf8-b954-2ad8-d59419d99cbf"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:31:31.712783
336	SYSTEM	11	\N	\N	1e2b70bf-6d18-4400-8b9e-d3959a0aff02	\N	2026-07-09 21:32:05.90269	{"sessionId": "636e2773-c9f5-ce57-0473-7688ec9d1ba7"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:32:05.90269
337	SYSTEM	11	\N	\N	ce89b229-5f54-40e2-ba03-99d817f92d30	\N	2026-07-09 21:32:10.589659	{"reason": "", "sessionId": "636e2773-c9f5-ce57-0473-7688ec9d1ba7"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:32:10.589659
338	SYSTEM	11	\N	\N	8b164f70-ec02-4f9c-a9fa-09da742d21f8	\N	2026-07-09 21:32:39.648152	{"sessionId": "36e973ed-3448-87ea-a3a3-9e4910d20345"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:32:39.648152
339	SYSTEM	11	\N	\N	7e9720d4-96f3-4e76-8187-3fee445529ec	\N	2026-07-09 21:32:43.748299	{"reason": "", "sessionId": "36e973ed-3448-87ea-a3a3-9e4910d20345"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:32:43.748299
340	SYSTEM	11	\N	\N	d90d8808-1e3e-404a-bb20-26e6a035821e	\N	2026-07-09 21:33:40.278509	{"sessionId": "3d205c42-9520-697d-8b64-5c63af112410"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:33:40.278509
341	RIDER	11	jomana	\N	f1c10500-b16a-4f31-b354-cf0f7b02a4a6	\N	2026-07-09 21:33:53.4282	{"rideType": "ECONOMY", "estimatedFare": 2.94, "pickupAddress": "26.3786, 50.1214", "dropoffAddress": "26.4001, 50.1171", "estimatedDistance": 4.685, "estimatedDuration": 7}	RIDE_REQUESTED	f	\N	\N	212	2026-07-09 21:33:53.4282
342	DRIVER	13	muasi	\N	0d68b54a-4bb7-4aac-a0d4-9e87e342c01a	\N	2026-07-09 21:34:14.147421	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	212	2026-07-09 21:34:14.147421
343	DRIVER	13	muasi	\N	03ebde3c-82f2-47f8-b70e-88c4f68006cc	\N	2026-07-09 21:35:06.162556	{}	DRIVER_ARRIVED	f	\N	\N	212	2026-07-09 21:35:06.162556
344	DRIVER	13	muasi	\N	8af61b06-f0b0-4998-bca0-4cf666bbcaa7	\N	2026-07-09 21:37:09.893156	{}	RIDE_STARTED	f	\N	\N	212	2026-07-09 21:37:09.893156
345	DRIVER	13	muasi	\N	c4478292-7b30-45a3-a73b-9324b15f793b	\N	2026-07-09 21:42:25.90008	{"finalFare": 2.94}	RIDE_COMPLETED	f	\N	\N	212	2026-07-09 21:42:25.90008
346	RIDER	11	jomana	\N	4b9d2c65-946b-45fd-85f1-ba870eadadcc	\N	2026-07-09 21:42:34.531495	{"amount": 2.94}	PAYMENT_CONFIRMED_CASH	f	\N	\N	212	2026-07-09 21:42:34.531495
347	SYSTEM	11	\N	\N	3d3f1e03-f9d8-4322-ac2e-e49be81d734a	\N	2026-07-09 21:42:45.5008	{"sessionId": "296c263c-43b2-af99-6177-5e27e35495c9"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:42:45.5008
348	SYSTEM	11	\N	\N	8dab994d-7011-454d-96c5-2dc18b108339	\N	2026-07-09 21:42:45.858341	{"reason": "", "sessionId": "3d205c42-9520-697d-8b64-5c63af112410"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:42:45.858341
349	DRIVER	13	muasi	\N	951302ea-76e8-46a0-9c0a-8865b1873af5	\N	2026-07-09 21:42:52.111376	{"appFee": 0.44, "netAmount": 2.50, "grossAmount": 2.94}	PAYMENT_RECEIVED	f	\N	\N	212	2026-07-09 21:42:52.111376
350	SYSTEM	13	\N	\N	16c77404-a8a5-4b62-bca5-c75e9113c47d	\N	2026-07-09 21:43:12.430044	{"sessionId": "073e6a8f-383e-65db-f54a-e29567775d7d"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 21:43:12.430044
390	SYSTEM	11	\N	\N	870fce63-8b3b-4aa1-811f-551bc82b3790	\N	2026-07-10 17:24:32.831571	{"sessionId": "40058023-8e95-a1d4-4d72-ae2206d308b0"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:24:32.831571
351	SYSTEM	11	\N	\N	b792f702-8200-4377-a1cb-788c027abfe2	\N	2026-07-09 21:44:04.774139	{"reason": "", "sessionId": "296c263c-43b2-af99-6177-5e27e35495c9"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:44:04.774139
352	SYSTEM	13	\N	\N	97150439-6524-4bb8-926d-9cc296c25f2f	\N	2026-07-09 21:46:08.902197	{"reason": "", "sessionId": "073e6a8f-383e-65db-f54a-e29567775d7d"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 21:46:08.902197
353	SYSTEM	13	\N	\N	64865acd-1471-4787-9e99-706ac31a9d07	\N	2026-07-09 22:37:20.902743	{"sessionId": "e79e1f58-e2c3-d900-82bd-8b71900786dc"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 22:37:20.902743
354	SYSTEM	11	\N	\N	9cb43ba9-3b6f-4e04-9225-929892356d88	\N	2026-07-09 22:37:41.81977	{"sessionId": "c2853454-376b-93ed-343f-80a17d905cad"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 22:37:41.81977
355	RIDER	11	jomana	\N	846a5a43-5d20-4984-a3fa-e590ebfaee21	\N	2026-07-09 22:38:15.372053	{"rideType": "ECONOMY", "estimatedFare": 3.81, "pickupAddress": "26.4005, 50.1188", "dropoffAddress": "26.3786, 50.1214", "estimatedDistance": 9.031, "estimatedDuration": 12}	RIDE_REQUESTED	f	\N	\N	213	2026-07-09 22:38:15.372053
356	DRIVER	13	muasi	\N	463ce830-b6a1-4451-9484-ecb167da2710	\N	2026-07-09 22:38:19.439937	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	213	2026-07-09 22:38:19.439937
357	DRIVER	13	muasi	\N	e4c7be10-b85c-4886-b104-1dff7a07f4b4	\N	2026-07-09 22:38:24.503	{}	DRIVER_ARRIVED	f	\N	\N	213	2026-07-09 22:38:24.503
358	DRIVER	13	muasi	\N	5de762f0-8e45-4310-8fc6-da6dbac623e0	\N	2026-07-09 22:38:33.296948	{}	RIDE_STARTED	f	\N	\N	213	2026-07-09 22:38:33.296948
359	DRIVER	13	muasi	\N	eb18a601-89cc-465b-ae0f-744b23b446b8	\N	2026-07-09 22:43:58.427324	{"finalFare": 3.81}	RIDE_COMPLETED	f	\N	\N	213	2026-07-09 22:43:58.427324
360	DRIVER	13	muasi	\N	bbea9ce8-b12c-43fb-8912-e557b02ccb4c	\N	2026-07-09 22:44:06.492628	{"appFee": 0.57, "netAmount": 3.24, "grossAmount": 3.81}	CASH_RECEIVED	f	\N	\N	213	2026-07-09 22:44:06.492628
361	SYSTEM	13	\N	\N	57854904-9993-4a73-9984-b67435a8cf4c	\N	2026-07-09 22:44:13.442553	{"reason": "", "sessionId": "e79e1f58-e2c3-d900-82bd-8b71900786dc"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 22:44:13.442553
362	SYSTEM	13	\N	\N	9e3d1283-bb3d-493e-a319-530387278d66	\N	2026-07-09 22:44:13.9864	{"sessionId": "982787f1-0bfc-129b-e918-b3118dd33008"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 22:44:13.985892
363	SYSTEM	11	\N	\N	0832bfd8-db2f-44ee-8b3e-4ae935ca03b1	\N	2026-07-09 22:44:34.24931	{"reason": "", "sessionId": "c2853454-376b-93ed-343f-80a17d905cad"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 22:44:34.24931
364	SYSTEM	11	\N	\N	1cd07782-5ca1-46ee-a11e-7859fef28c51	\N	2026-07-09 22:44:34.871177	{"sessionId": "d9a572a1-a5f6-978c-3bdb-e82b11a538c3"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-09 22:44:34.871177
365	SYSTEM	13	\N	\N	083df800-8d1c-468e-8381-967804287d27	\N	2026-07-09 22:44:38.372688	{"reason": "", "sessionId": "982787f1-0bfc-129b-e918-b3118dd33008"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 22:44:38.372688
366	SYSTEM	11	\N	\N	6063d28e-5ba6-41f8-9902-2b28f2f6f13f	\N	2026-07-09 22:44:53.117726	{"reason": "", "sessionId": "d9a572a1-a5f6-978c-3bdb-e82b11a538c3"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-09 22:44:53.117726
367	DRIVER	13	muasi	\N	efed97d5-2ef5-4679-96e1-d280f3ae588f	\N	2026-07-10 17:20:40.021443	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-10 17:20:40.021443
368	SYSTEM	13	\N	\N	4261d202-0f0c-41ec-a8a7-fb5538481e73	\N	2026-07-10 17:20:42.083411	{"sessionId": "fc221c3b-c69e-0942-0239-9c6a041af874"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:20:42.083411
369	RIDER	11	jomana	\N	e209cf0f-fc54-4187-a3c9-44e2312e0448	\N	2026-07-10 17:20:44.308814	{"email": "diarjojo89@gmail.com"}	LOGIN	f	\N	\N	\N	2026-07-10 17:20:44.308814
370	SYSTEM	11	\N	\N	dece3c46-ad6e-413f-9fba-ba1cee82c9ad	\N	2026-07-10 17:20:45.10972	{"sessionId": "7602f7e8-f260-cd41-eb72-cbf4ddceb3ba"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:20:45.10972
371	RIDER	11	jomana	\N	4b70fedf-50a3-44f3-8b75-d705a765429d	\N	2026-07-10 17:21:08.745347	{"rideType": "ECONOMY", "estimatedFare": 2.11, "pickupAddress": "26.3786, 50.1214", "dropoffAddress": "26.3773, 50.1193", "estimatedDistance": 0.534, "estimatedDuration": 3}	RIDE_REQUESTED	f	\N	\N	214	2026-07-10 17:21:08.745347
372	DRIVER	13	muasi	\N	dd96b958-5a77-42e5-a7a1-6f6dd8aeac59	\N	2026-07-10 17:21:13.884083	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	214	2026-07-10 17:21:13.884083
373	DRIVER	13	muasi	\N	a173b914-6b78-4ecd-8628-89f38dce569c	\N	2026-07-10 17:21:28.57685	{}	DRIVER_ARRIVED	f	\N	\N	214	2026-07-10 17:21:28.57685
374	DRIVER	13	muasi	\N	47cb10b6-3df9-461f-8b69-07893f9a499a	\N	2026-07-10 17:21:46.825346	{}	RIDE_STARTED	f	\N	\N	214	2026-07-10 17:21:46.825346
375	DRIVER	13	muasi	\N	7907ac58-5160-42cc-9856-8a59c18210e8	\N	2026-07-10 17:22:11.979578	{"finalFare": 2.11}	RIDE_COMPLETED	f	\N	\N	214	2026-07-10 17:22:11.979578
376	DRIVER	13	muasi	\N	e52fffa1-8000-4e33-8032-ef0050d41fee	\N	2026-07-10 17:22:24.123455	{"appFee": 0.32, "netAmount": 1.79, "grossAmount": 2.11}	CASH_RECEIVED	f	\N	\N	214	2026-07-10 17:22:24.123455
377	SYSTEM	11	\N	\N	206750e1-2b4a-4ce7-afd9-f5689e126608	\N	2026-07-10 17:22:24.848956	{"reason": "", "sessionId": "7602f7e8-f260-cd41-eb72-cbf4ddceb3ba"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:22:24.848956
378	SYSTEM	11	\N	\N	435c311c-3b1c-4d8e-a3a3-df0e6c39903b	\N	2026-07-10 17:22:25.151771	{"sessionId": "fbf566b8-28b9-5124-1ad7-d50b3e86355d"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:22:25.151771
379	SYSTEM	13	\N	\N	afc8d67d-fbcb-476b-8ab8-9b39fe56911f	\N	2026-07-10 17:22:31.987404	{"reason": "", "sessionId": "fc221c3b-c69e-0942-0239-9c6a041af874"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:22:31.987404
380	SYSTEM	13	\N	\N	d78266eb-b09a-44a3-a50f-9fa1f9cb9cb7	\N	2026-07-10 17:22:32.253099	{"sessionId": "a6357830-7148-ecc6-06e0-4e8c05349098"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:22:32.253099
381	RIDER	11	jomana	\N	5b73b79c-b048-426e-a140-719508d399db	\N	2026-07-10 17:22:44.55769	{"rideType": "ECONOMY", "estimatedFare": 2.11, "pickupAddress": "26.3786, 50.1214", "dropoffAddress": "26.3777, 50.1191", "estimatedDistance": 0.571, "estimatedDuration": 3}	RIDE_REQUESTED	f	\N	\N	215	2026-07-10 17:22:44.55769
382	DRIVER	13	muasi	\N	53a52d09-b35c-4d84-910e-6f016003ba65	\N	2026-07-10 17:22:50.164342	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	215	2026-07-10 17:22:50.164342
383	SYSTEM	11	\N	\N	15856d94-e83d-454b-aa7d-246432b51fb0	\N	2026-07-10 17:22:57.323823	{"reason": "", "sessionId": "fbf566b8-28b9-5124-1ad7-d50b3e86355d"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:22:57.323823
384	DRIVER	13	muasi	\N	41716eda-bbc2-4d1a-9f8d-b632560869f0	\N	2026-07-10 17:23:05.519365	{}	DRIVER_ARRIVED	f	\N	\N	215	2026-07-10 17:23:05.519365
385	SYSTEM	11	\N	\N	782eef5e-7692-471a-b057-d02aff9b3e74	\N	2026-07-10 17:23:32.569022	{"sessionId": "c8219c9c-b93f-6f82-21c4-512a8b91a4cd"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:23:32.569022
386	DRIVER	13	muasi	\N	decdac26-2f00-4f0b-b2ef-1fa18ae53969	\N	2026-07-10 17:23:46.28828	{}	RIDE_STARTED	f	\N	\N	215	2026-07-10 17:23:46.28828
387	SYSTEM	11	\N	\N	f8524f99-9d41-4700-8c1b-c7c6daef4b98	\N	2026-07-10 17:23:55.582166	{"reason": "", "sessionId": "c8219c9c-b93f-6f82-21c4-512a8b91a4cd"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:23:55.582166
388	DRIVER	13	muasi	\N	8e94be55-5fe6-4ac2-a6c3-4f3c78b2676c	\N	2026-07-10 17:24:13.725372	{"finalFare": 2.11}	RIDE_COMPLETED	f	\N	\N	215	2026-07-10 17:24:13.725372
389	DRIVER	13	muasi	\N	9faf5b92-27f1-4aff-89aa-f2ce87e65323	\N	2026-07-10 17:24:29.424754	{"appFee": 0.32, "netAmount": 1.79, "grossAmount": 2.11}	CASH_RECEIVED	f	\N	\N	215	2026-07-10 17:24:29.424754
391	SYSTEM	13	\N	\N	b5555b83-431e-455f-91f7-7f5cdfa60657	\N	2026-07-10 17:24:36.709145	{"reason": "", "sessionId": "a6357830-7148-ecc6-06e0-4e8c05349098"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:24:36.709145
392	SYSTEM	13	\N	\N	fec04195-b982-4a1d-8322-17cdd6a537cb	\N	2026-07-10 17:24:36.999245	{"sessionId": "1029dd6f-2854-de96-8f61-85002fcfebf7"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:24:36.999245
393	SYSTEM	11	\N	\N	634ac50f-d362-408c-aa27-d292db7c8dee	\N	2026-07-10 17:25:35.996269	{"reason": "", "sessionId": "40058023-8e95-a1d4-4d72-ae2206d308b0"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:25:35.996269
394	SYSTEM	11	\N	\N	09554a0c-1cb5-40bc-9535-8f8e8e12def3	\N	2026-07-10 17:39:21.52631	{"sessionId": "2c0dfe46-a943-4c01-0228-a4ed247d108a"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:39:21.52631
395	SYSTEM	11	\N	\N	734f10d6-6384-4dac-8ede-5b47eb17594e	\N	2026-07-10 17:39:22.510872	{"reason": "", "sessionId": "2c0dfe46-a943-4c01-0228-a4ed247d108a"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:39:22.510872
397	SYSTEM	13	\N	\N	4efab529-4d9a-4a38-97d6-b3793b7295b8	\N	2026-07-10 17:44:55.694205	{"reason": "", "sessionId": "1029dd6f-2854-de96-8f61-85002fcfebf7"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:44:55.694205
398	RIDER	11	jomana	\N	a766c461-43e5-4396-8ed1-25b3e5cd589e	\N	2026-07-10 17:45:22.894456	{"rideType": "ECONOMY", "estimatedFare": 3.68, "pickupAddress": "26.3786, 50.1214", "dropoffAddress": "26.3996, 50.0657", "estimatedDistance": 8.41, "estimatedDuration": 13}	RIDE_REQUESTED	f	\N	\N	216	2026-07-10 17:45:22.894456
399	DRIVER	13	muasi	\N	6134eabf-759e-415c-884c-c9f4252a650e	\N	2026-07-10 17:45:48.924375	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	216	2026-07-10 17:45:48.924375
396	SYSTEM	11	\N	\N	e0ad969b-6030-4330-96f7-b5ac152e6974	\N	2026-07-10 17:39:55.230416	{"sessionId": "93da1d48-a574-6f69-0d0d-a0c28eec6812"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:39:55.230416
400	DRIVER	13	muasi	\N	42d1b09a-ecac-48d2-b2ff-d8555c54d52a	\N	2026-07-10 17:46:55.118445	{}	DRIVER_ARRIVED	f	\N	\N	216	2026-07-10 17:46:55.118445
401	DRIVER	13	muasi	\N	9661a012-a798-483c-8261-55d2aabfbec4	\N	2026-07-10 17:48:55.960195	{}	RIDE_STARTED	f	\N	\N	216	2026-07-10 17:48:55.960195
402	SYSTEM	11	\N	\N	135f24e6-4d96-43bc-8b88-950e1ecaa7e2	\N	2026-07-10 17:51:14.447778	{"sessionId": "a36284f4-e36e-ea16-d80a-cb41061ca62c"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 17:51:14.447778
403	SYSTEM	11	\N	\N	cdc2f9e0-4bd9-45d1-9c09-d4af82e12280	\N	2026-07-10 17:51:14.756432	{"reason": "", "sessionId": "93da1d48-a574-6f69-0d0d-a0c28eec6812"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 17:51:14.756432
404	SYSTEM	11	\N	\N	6c074da0-cc8a-4983-ad89-fa6272bf06c7	\N	2026-07-10 18:02:24.654395	{"reason": "", "sessionId": "a36284f4-e36e-ea16-d80a-cb41061ca62c"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 18:02:24.654395
405	SYSTEM	11	\N	\N	b8a7c7fc-37f8-4b1e-8719-04c86f32997f	\N	2026-07-10 18:02:41.521216	{"sessionId": "a93f928b-6508-5d3a-fbf2-f218b45184cb"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 18:02:41.521216
406	DRIVER	13	muasi	\N	fb3f6301-4321-497c-9c2e-00bc028efa06	\N	2026-07-10 18:02:45.224676	{"finalFare": 3.68}	RIDE_COMPLETED	f	\N	\N	216	2026-07-10 18:02:45.224676
407	SYSTEM	11	\N	\N	102ed43b-50e4-4ad1-9e9f-dc3e42163a20	\N	2026-07-10 18:02:55.994903	{"reason": "", "sessionId": "a93f928b-6508-5d3a-fbf2-f218b45184cb"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 18:02:55.994903
408	SYSTEM	11	\N	\N	68bbcb74-6a72-4b01-95d4-de7d6daef7a2	\N	2026-07-10 18:02:56.719849	{"sessionId": "b7ea158d-a528-abd4-78aa-a1e839daf1e1"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 18:02:56.719849
409	SYSTEM	13	\N	\N	5562d9f2-4b12-4af8-a866-b325f45c2f60	\N	2026-07-10 18:03:32.012427	{"sessionId": "bada7b40-21fc-d580-ebb0-904fce51a8ca"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 18:03:32.012427
410	SYSTEM	11	\N	\N	8e907a01-a81a-4611-919f-9195b29c7b0b	\N	2026-07-10 18:03:42.382362	{"reason": "", "sessionId": "b7ea158d-a528-abd4-78aa-a1e839daf1e1"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 18:03:42.382362
411	SYSTEM	13	\N	\N	110194d8-872d-44fd-99a2-2e6e8e1cd49a	\N	2026-07-10 18:21:43.728382	{"reason": "", "sessionId": "bada7b40-21fc-d580-ebb0-904fce51a8ca"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 18:21:43.728382
412	SYSTEM	13	\N	\N	f225a3ab-05d4-4883-8c33-f6c967161f4c	\N	2026-07-10 19:10:21.363623	{"sessionId": "cb00f92d-195c-36ac-ff66-71f5addbae59"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 19:10:21.363623
413	RIDER	11	jomana	\N	438b0a74-801e-47c2-adfb-374cc63df115	\N	2026-07-10 19:11:38.64826	{"rideType": "LUXURY", "estimatedFare": 11.55, "pickupAddress": "26.3878, 50.0754", "dropoffAddress": "26.4006, 50.1152", "estimatedDistance": 11.098, "estimatedDuration": 17}	RIDE_REQUESTED	f	\N	\N	217	2026-07-10 19:11:38.64826
414	SYSTEM	11	\N	\N	fe09f038-48a3-4530-8c41-89ba2cce4d30	\N	2026-07-10 19:11:40.019928	{"sessionId": "c535f058-976e-8ff0-24c8-4e9cafebbd59"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 19:11:40.019928
415	DRIVER	13	muasi	\N	70b3850e-c1b1-4dbc-8c04-4cfd7f8a3909	\N	2026-07-10 19:11:46.574026	{"driverId": 13, "driverName": "muasi"}	RIDE_ACCEPTED	f	\N	\N	217	2026-07-10 19:11:46.574026
416	DRIVER	13	muasi	\N	bbd3247a-e2a4-40e0-a5bc-7aa0a8e01c3f	\N	2026-07-10 19:11:55.280771	{}	DRIVER_ARRIVED	f	\N	\N	217	2026-07-10 19:11:55.280771
417	DRIVER	13	muasi	\N	2a21c704-aef1-4a86-88dc-b90432c765c9	\N	2026-07-10 19:12:00.878511	{}	RIDE_STARTED	f	\N	\N	217	2026-07-10 19:12:00.878511
418	SYSTEM	11	\N	\N	c01e4fab-2d49-4229-ae32-d1e46669f90a	\N	2026-07-10 19:15:06.476195	{"reason": "", "sessionId": "c535f058-976e-8ff0-24c8-4e9cafebbd59"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 19:15:06.475998
419	SYSTEM	11	\N	\N	d67eba24-03b4-471f-a217-118d8eb93d60	\N	2026-07-10 19:15:09.698157	{"sessionId": "176dc865-afc2-5c55-7e8b-e4223686e3cb"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 19:15:09.698157
420	DRIVER	13	muasi	\N	cfa78657-5b0e-4e5f-9930-a3ab37fc8043	\N	2026-07-10 19:24:53.101016	{"finalFare": 11.55}	RIDE_COMPLETED	f	\N	\N	217	2026-07-10 19:24:53.101016
421	DRIVER	13	muasi	\N	ad518b17-1d35-4e93-b0a7-3e78b168f359	\N	2026-07-10 19:25:00.724918	{"appFee": 1.73, "netAmount": 9.82, "grossAmount": 11.55}	CASH_RECEIVED	f	\N	\N	217	2026-07-10 19:25:00.724918
422	SYSTEM	11	\N	\N	9ca5cc05-308f-4549-a1ae-daa3fc05b096	\N	2026-07-10 19:25:02.583359	{"reason": "", "sessionId": "176dc865-afc2-5c55-7e8b-e4223686e3cb"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 19:25:02.583359
423	SYSTEM	11	\N	\N	65166d14-accd-404a-8512-1552986f54a2	\N	2026-07-10 19:25:03.206984	{"sessionId": "dac072e2-086d-2f1a-20e0-92174c1a510c"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 19:25:03.206984
424	SYSTEM	13	\N	\N	66584570-2527-4332-84f2-ee013fe41fb4	\N	2026-07-10 19:25:03.60106	{"reason": "", "sessionId": "cb00f92d-195c-36ac-ff66-71f5addbae59"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 19:25:03.60106
425	SYSTEM	13	\N	\N	2c655145-5f97-4d20-aafa-c567794ab1d6	\N	2026-07-10 19:25:04.190549	{"sessionId": "25ab3c35-9ae8-21f7-7938-55720c5a2ae2"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 19:25:04.190549
426	SYSTEM	13	\N	\N	b3fa947a-e436-494d-bc9c-84d76e0144b8	\N	2026-07-10 19:25:10.328046	{"reason": "", "sessionId": "25ab3c35-9ae8-21f7-7938-55720c5a2ae2"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 19:25:10.328046
427	SYSTEM	11	\N	\N	14f6dba3-2eba-4e0b-ac78-47cf68ef4a21	\N	2026-07-10 19:26:15.651751	{"reason": "", "sessionId": "dac072e2-086d-2f1a-20e0-92174c1a510c"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 19:26:15.651751
428	RIDER	12	Abdulrahman	\N	c2958611-0135-4717-be1c-fcc46690edc0	\N	2026-07-10 20:10:48.560587	{"email": "aboudiassi2014@gmail.com"}	LOGIN	f	\N	\N	\N	2026-07-10 20:10:48.560587
429	SYSTEM	12	\N	\N	4761e213-f85d-4b75-abef-4046509b664c	\N	2026-07-10 20:10:50.616595	{"sessionId": "a0007c62-b8bf-a222-0ed9-956740b5befb"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 20:10:50.616595
430	SYSTEM	12	\N	\N	3ff872b5-95bf-448d-89f0-ea0c4b2ae971	\N	2026-07-10 20:11:04.510666	{"reason": "", "sessionId": "a0007c62-b8bf-a222-0ed9-956740b5befb"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 20:11:04.510666
431	RIDER	12	Abdulrahman	\N	fdf30672-3319-496e-b048-c9cbe5ec48cd	\N	2026-07-10 20:18:17.309694	{"email": "aboudiassi2014@gmail.com"}	LOGIN	f	\N	\N	\N	2026-07-10 20:18:17.309694
432	SYSTEM	12	\N	\N	edc3eaf6-1e67-40bf-a67e-a5be9c352880	\N	2026-07-10 20:18:18.596303	{"sessionId": "578067dc-5141-52d1-691e-1f1d4b5a0dd3"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 20:18:18.596303
433	SYSTEM	12	\N	\N	cfe3b934-9455-4dc5-bd49-a03650f70dcc	\N	2026-07-10 20:18:47.159865	{"reason": "", "sessionId": "578067dc-5141-52d1-691e-1f1d4b5a0dd3"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 20:18:47.159865
434	RIDER	12	Abdulrahman	\N	f753b75b-fa40-4253-8979-4e26ed4737f0	\N	2026-07-10 20:21:00.256099	{"rideType": "ECONOMY", "estimatedFare": 2.20, "pickupAddress": "26.3785, 50.1213", "dropoffAddress": "26.3770, 50.1188", "estimatedDistance": 1.003, "estimatedDuration": 4}	RIDE_REQUESTED	f	\N	\N	218	2026-07-10 20:21:00.256099
435	SYSTEM	12	\N	\N	adb95081-0f77-423b-96f0-55bc6d502236	\N	2026-07-10 20:21:00.771664	{"sessionId": "d00c48f2-72c6-afbd-50ae-06a949e10dfa"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 20:21:00.771664
436	SYSTEM	13	\N	\N	37dd374d-6276-40cc-8bb4-34458a17c8ec	\N	2026-07-10 20:21:23.970605	{"sessionId": "5ee25b92-0e4c-17c6-3a08-7ee774053649"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 20:21:23.970605
437	SYSTEM	13	\N	\N	65f40df8-7fa6-4ec0-97e0-b33c7f1c4d6c	\N	2026-07-10 20:21:45.221275	{"reason": "", "sessionId": "5ee25b92-0e4c-17c6-3a08-7ee774053649"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 20:21:45.221275
438	RIDER	12	Abdulrahman	\N	d2746059-16b5-477c-aff1-70903788ac0d	\N	2026-07-10 20:21:47.950323	{"reason": "Rider cancelled search"}	RIDE_CANCELLED	f	\N	\N	218	2026-07-10 20:21:47.950323
439	SYSTEM	12	\N	\N	3a2fadf7-e141-40a0-a5a9-741fcdd63f86	\N	2026-07-10 20:21:48.19892	{"reason": "", "sessionId": "d00c48f2-72c6-afbd-50ae-06a949e10dfa"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 20:21:48.19892
440	SYSTEM	12	\N	\N	babeaa89-d968-48b8-97f7-8a242add5b01	\N	2026-07-10 20:21:48.602164	{"sessionId": "b75e86dd-0165-5810-fe28-37d3c91057ef"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-10 20:21:48.602164
441	SYSTEM	12	\N	\N	4a802d9e-fe33-4fc7-ae80-0ad3f1f5dab5	\N	2026-07-10 20:21:55.295432	{"reason": "", "sessionId": "b75e86dd-0165-5810-fe28-37d3c91057ef"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-10 20:21:55.295432
442	ADMIN	1	Mustafa Assi	\N	af49efbc-63de-4801-87b8-d3b8232738a0	\N	2026-07-11 13:25:24.211856	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-11 13:25:24.211856
443	ADMIN	1	Mustafa Assi	\N	b33d1b0b-69eb-42aa-95ea-731e802310d7	\N	2026-07-11 13:26:10.342891	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-11 13:26:10.342891
444	ADMIN	1	Mustafa Assi	\N	a1ef6a33-1c70-47bd-a9d9-59ad5d7f9fc6	\N	2026-07-11 13:37:55.141271	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-11 13:37:55.141271
445	ADMIN	1	Mustafa Assi	\N	81206ad6-f646-446e-8e3b-6957ef514913	\N	2026-07-11 13:50:01.312625	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-11 13:50:01.312625
446	SYSTEM	1	\N	\N	8a15ff07-bbbc-424c-88b1-f208481659b8	\N	2026-07-11 13:50:02.589598	{"sessionId": "ee4e79e5-9bc8-5dd5-7d00-ae36377d6814"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-11 13:50:02.589598
447	ADMIN	1	\N	\N	b0fa00c1-73f7-4670-b6d7-9ed8175a340e	\N	2026-07-11 13:50:15.065158	{}	ADMIN_VIEWED_RIDE	f	\N	\N	217	2026-07-11 13:50:15.065158
448	FLUTTER	\N	FLUTTER	\N	54c5e445-b2d6-4488-940f-d4502d895ff7	\N	2026-07-11 13:50:31.917102	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminTripDetails-Overview"}	APP_RESUMED	f	\N	\N	217	2026-07-11 13:50:31.917102
449	ADMIN	1	Mustafa Assi	\N	6fe7c0c4-eea3-4658-8ec5-8dea300c1b9f	\N	2026-07-11 13:54:03.303988	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-11 13:54:03.303988
450	USER	1	\N	\N	ba09f84e-fb3f-406f-9f48-4f83fa958ccc	\N	2026-07-11 13:54:04.004631	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-11 13:54:04.003633
451	SYSTEM	1	\N	\N	9d9f98b3-d891-44cf-9a21-c39edd2a00df	\N	2026-07-11 13:54:04.533088	{"sessionId": "b25c67ed-3e36-b0b1-f8f3-1cfa18d48ade"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-11 13:54:04.533088
452	SYSTEM	1	\N	\N	08604bf1-a450-494e-8660-ed402f562578	\N	2026-07-11 13:54:04.775572	{"reason": "", "sessionId": "ee4e79e5-9bc8-5dd5-7d00-ae36377d6814"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-11 13:54:04.775572
453	FLUTTER	\N	FLUTTER	\N	0db95dda-955f-4231-833b-679250a72c0f	\N	2026-07-11 13:54:05.180507	{"summary": "Navigated to Splash", "category": "FRONTEND", "severity": "INFO", "screenName": "Splash"}	SCREEN_OPENED	f	\N	\N	217	2026-07-11 13:54:05.180507
454	FLUTTER	\N	FLUTTER	\N	cb8cc673-802d-4a05-ab97-8f84626aa059	\N	2026-07-11 13:54:05.321902	{"summary": "Force logout snackbar: signed out from another device", "category": "UI", "severity": "INFO", "screenName": "RiderHomeScreen", "snackbarType": "force_logout"}	SNACKBAR_SHOWN	f	\N	\N	217	2026-07-11 13:54:05.321902
455	ADMIN	1	\N	\N	3ac03af3-1695-45d9-a67a-d59bd43de844	\N	2026-07-11 13:54:18.045192	{}	ADMIN_VIEWED_RIDE	f	\N	\N	217	2026-07-11 13:54:18.045192
456	ADMIN	1	\N	\N	2d5ad73b-cf45-4879-8a3c-e615ec5181bf	\N	2026-07-11 13:56:49.28946	{}	ADMIN_VIEWED_RIDE	f	\N	\N	215	2026-07-11 13:56:49.28946
457	FLUTTER	\N	FLUTTER	\N	3fe72352-ebb1-49d3-9d14-e07e0e8cb683	\N	2026-07-11 13:56:49.346596	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-11 13:56:49.345598
458	FLUTTER	\N	FLUTTER	\N	3f7c659e-2440-4826-a68b-c4552335c052	\N	2026-07-11 13:57:31.317796	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	APP_RESUMED	f	\N	\N	215	2026-07-11 13:57:31.317796
459	FLUTTER	\N	FLUTTER	\N	18912f06-cdc8-4ba6-941a-dab3e6b91d15	\N	2026-07-11 13:57:32.908532	{"summary": "Application sent to background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	APP_BACKGROUNDED	f	\N	\N	215	2026-07-11 13:57:32.908532
460	FLUTTER	\N	FLUTTER	\N	187ecd0b-d3c2-4c2d-b132-cc0f9c370505	\N	2026-07-11 13:57:40.054363	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	APP_RESUMED	f	\N	\N	215	2026-07-11 13:57:40.054363
461	FLUTTER	\N	FLUTTER	\N	d938ffe1-4bb9-47ac-b204-af718f070bcb	\N	2026-07-11 13:57:40.870796	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	215	2026-07-11 13:57:40.870796
462	FLUTTER	\N	FLUTTER	\N	eab5e83b-2fae-4f94-ac5f-998414bbdb3b	\N	2026-07-11 13:57:40.884756	{"summary": "SETTINGS_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "SettingsScreen"}	SETTINGS_OPENED	f	\N	\N	215	2026-07-11 13:57:40.884756
463	FLUTTER	\N	FLUTTER	\N	2ca97e9f-a7a6-454c-80e5-7d66ff1263dc	\N	2026-07-11 13:57:44.662477	{"summary": "Navigated to MaterialPageRoute<Map<String, dynamic>>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<Map<String, dynamic>>"}	SCREEN_OPENED	f	\N	\N	215	2026-07-11 13:57:44.662477
464	FLUTTER	\N	FLUTTER	\N	83992831-4b34-414e-8814-9d45e036d497	\N	2026-07-11 13:57:44.668314	{"summary": "User initiated ride request", "category": "BUSINESS", "severity": "INFO", "screenName": "RiderHomeScreen"}	RIDE_REQUEST_INITIATED	f	\N	\N	215	2026-07-11 13:57:44.668314
465	FLUTTER	\N	FLUTTER	\N	874fd240-c18a-49cd-aaca-5ccdb2ee0b9c	\N	2026-07-11 13:57:49.986548	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	215	2026-07-11 13:57:49.986548
466	FLUTTER	\N	FLUTTER	\N	f05c05ec-eb16-4bce-97f7-e98dc72af660	\N	2026-07-11 13:58:01.787704	{"summary": "Application sent to background", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	APP_BACKGROUNDED	f	\N	\N	215	2026-07-11 13:58:01.787704
467	SYSTEM	1	\N	\N	d804d906-45cc-4c4a-9749-33b0a952c3df	\N	2026-07-11 13:58:02.042312	{"reason": "", "sessionId": "b25c67ed-3e36-b0b1-f8f3-1cfa18d48ade"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-11 13:58:02.042312
468	DRIVER	13	muasi	\N	78e40363-ea7e-4bdf-8929-f31320c28f99	\N	2026-07-12 11:14:11.29309	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-12 11:14:11.29309
469	DRIVER	13	muasi	\N	23f3028e-8cbd-4d46-81c0-c96bce6a4d93	\N	2026-07-12 11:34:46.493524	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-12 11:34:46.493524
470	DRIVER	7	Mike Driver	\N	2bf1beda-3eb7-48ab-9875-c06e77aeda3a	\N	2026-07-12 11:35:34.041467	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 11:35:34.041467
471	DRIVER	7	Mike Driver	\N	865b16e9-dee4-409f-bf48-037da34dc0fc	\N	2026-07-12 11:37:01.953515	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 11:37:01.953515
472	DRIVER	7	Mike Driver	\N	90b1739c-b0c9-41dc-9e18-60397e490de2	\N	2026-07-12 11:47:41.022379	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 11:47:41.022379
473	SYSTEM	7	\N	\N	a0ef1def-0a1a-437c-90ed-bd30efbf1270	\N	2026-07-12 11:47:43.248984	{"sessionId": "f8ba805f-c15a-671b-a8c8-e2ba052205e6"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 11:47:43.248984
474	DRIVER	7	\N	\N	8c9e6a25-45ca-4929-85fd-37f827cbcf42	\N	2026-07-12 11:47:47.867505	{"category": "BUSINESS"}	DRIVER_WENT_ONLINE	f	\N	\N	\N	2026-07-12 11:47:47.867505
475	USER	7	\N	\N	025cbc74-dd1e-40da-8cda-5f6c2ce74631	\N	2026-07-12 11:48:01.274073	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 11:48:01.274073
477	ADMIN	1	Mustafa Assi	\N	91b4d556-524c-4315-ac4c-7f0572e52edc	\N	2026-07-12 11:48:15.914719	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-12 11:48:15.914719
476	SYSTEM	7	\N	\N	6a1a7ffd-e110-4aa2-a555-eacc9910c3a5	\N	2026-07-12 11:48:02.087957	{"reason": "", "sessionId": "f8ba805f-c15a-671b-a8c8-e2ba052205e6"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 11:48:02.087957
478	SYSTEM	1	\N	\N	9bad4ebf-139b-43d6-be1f-1703e0d2774b	\N	2026-07-12 11:48:16.819049	{"sessionId": "3da16f2c-51d0-8ff1-6110-3b0071f28ef4"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 11:48:16.819049
479	ADMIN	1	\N	\N	e58dbfbe-5789-4e18-ab9c-d71380af0a97	\N	2026-07-12 11:48:23.557888	{"driverId": 7}	ADMIN_VIEWED_DRIVER	f	\N	\N	\N	2026-07-12 11:48:23.557888
480	ADMIN	1	\N	\N	de319f05-cc10-47c7-b8a6-ff6096ef3a4a	\N	2026-07-12 11:48:39.308287	{}	ADMIN_VIEWED_RIDE	f	\N	\N	217	2026-07-12 11:48:39.308287
481	FLUTTER	\N	FLUTTER	\N	d2334ef1-0a47-4ce1-960b-e38c716fe4de	\N	2026-07-12 11:48:54.131167	{"outcome": "displayed", "summary": "Snackbar", "category": "UI", "dialogText": "Timeline copied to clipboard", "screenName": "AdminTripDetails-Behaviour", "uiElementType": "Snackbar"}	UI_SNACKBAR_SHOWN	f	\N	\N	217	2026-07-12 11:48:54.131167
482	FLUTTER	\N	FLUTTER	\N	28a86112-c94c-4409-b240-a2c3f6771b8e	\N	2026-07-12 11:50:04.772686	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	APP_RESUMED	f	\N	\N	217	2026-07-12 11:50:04.772686
483	FLUTTER	\N	FLUTTER	\N	71759b6f-b8b2-4912-8784-68b00e705277	\N	2026-07-12 11:50:10.872394	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	APP_RESUMED	f	\N	\N	217	2026-07-12 11:50:10.872394
484	FLUTTER	\N	FLUTTER	\N	2e7bcd50-eec3-4724-8157-7cc75786ad6e	\N	2026-07-12 11:50:14.364832	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	APP_RESUMED	f	\N	\N	217	2026-07-12 11:50:14.36471
485	FLUTTER	\N	FLUTTER	\N	0db4bb93-3fee-49a4-ae21-cf5a63099588	\N	2026-07-12 11:50:24.622888	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	APP_RESUMED	f	\N	\N	217	2026-07-12 11:50:24.622888
486	FLUTTER	\N	FLUTTER	\N	e125173a-85f1-4a33-aba5-439de62aa748	\N	2026-07-12 11:50:33.804532	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	217	2026-07-12 11:50:33.804532
487	FLUTTER	\N	FLUTTER	\N	2953c481-755c-410a-b14a-a7d6d9cc3882	\N	2026-07-12 11:50:33.861766	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 11:50:33.861766
488	USER	1	\N	\N	11a356c1-c33a-4644-aaba-264b7e8239c8	\N	2026-07-12 11:50:35.348961	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 11:50:35.348961
489	SYSTEM	1	\N	\N	f2b53eae-0cef-41b0-a7c3-dbdafc83efcd	\N	2026-07-12 11:50:35.858981	{"reason": "", "sessionId": "3da16f2c-51d0-8ff1-6110-3b0071f28ef4"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 11:50:35.858981
491	FLUTTER	\N	FLUTTER	\N	dda034e9-053f-4e29-996c-bdf948ac8f72	\N	2026-07-12 11:50:40.287656	{"summary": "Navigated to Rider-home", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 11:50:40.287656
492	FLUTTER	\N	FLUTTER	\N	6419b147-b950-4a16-8cdb-77de1e3bde9f	\N	2026-07-12 11:50:40.29981	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	217	2026-07-12 11:50:40.29981
493	SYSTEM	6	\N	\N	56c03f10-1444-4e5b-b627-a345c394663a	\N	2026-07-12 11:50:41.014168	{"sessionId": "07a71d9c-2402-cc9d-f953-ef2509980339"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 11:50:41.014168
494	FLUTTER	\N	FLUTTER	\N	3632c74c-3d22-4053-965f-1d6218bc12f5	\N	2026-07-12 11:50:52.344157	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	217	2026-07-12 11:50:52.344157
495	FLUTTER	\N	FLUTTER	\N	ae6bbd7b-682b-478d-8c13-9d2f1e8435f4	\N	2026-07-12 11:50:55.121639	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 11:50:55.121639
496	FLUTTER	\N	FLUTTER	\N	b9edc6a0-594e-49c8-b875-e216ad4f8bc3	\N	2026-07-12 11:51:13.331473	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	APP_RESUMED	f	\N	\N	217	2026-07-12 11:51:13.331473
497	FLUTTER	\N	FLUTTER	\N	9743c612-edfb-4b0d-ab35-95ee45484923	\N	2026-07-12 11:51:20.260333	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	217	2026-07-12 11:51:20.260333
499	USER	6	\N	\N	a78bf6f3-31fd-46c1-9d21-8f2990baffc2	\N	2026-07-12 11:51:21.916995	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 11:51:21.916995
500	SYSTEM	6	\N	\N	f3e32037-5be1-486c-a1a3-adc1355630ca	\N	2026-07-12 11:51:22.498704	{"reason": "", "sessionId": "07a71d9c-2402-cc9d-f953-ef2509980339"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 11:51:22.498704
490	RIDER	6	John Rider	\N	c80d8d3b-db3b-4bdf-a42a-0fd86fb4c82d	\N	2026-07-12 11:50:40.016303	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 11:50:40.016303
498	FLUTTER	\N	FLUTTER	\N	d986e6c1-56df-4c97-8a62-281470e5c4f0	\N	2026-07-12 11:51:20.261329	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 11:51:20.261329
501	DRIVER	7	Mike Driver	\N	48514ab1-c9fe-4951-915b-f0a82106a4e4	\N	2026-07-12 11:56:22.235572	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 11:56:22.235572
502	DRIVER	13	muasi	\N	e3930c64-1e41-4991-90cc-f0f53265d3de	\N	2026-07-12 13:30:14.10872	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-12 13:30:14.10872
503	DRIVER	13	muasi	\N	e6377205-d7ac-4b78-bcbb-aecf65b32b69	\N	2026-07-12 13:31:30.172734	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-12 13:31:30.172734
504	USER	13	\N	\N	d69b44d5-a11e-4126-af73-72f8fd469876	\N	2026-07-12 13:31:31.213296	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-12 13:31:31.213296
505	SYSTEM	13	\N	\N	8d5b6c68-0a41-4e36-8fdf-f71c14776d44	\N	2026-07-12 13:31:32.427596	{"sessionId": "6e5b6953-6407-baf5-1b43-8eabd48272f4"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 13:31:32.427596
506	DRIVER	13	\N	\N	f4939d82-333b-4776-a6dc-c35a00c68b60	\N	2026-07-12 13:32:17.690357	{"category": "BUSINESS"}	DRIVER_WENT_ONLINE	f	\N	\N	\N	2026-07-12 13:32:17.690357
507	USER	13	\N	\N	ac10b2ec-4d4b-4278-9fc2-2d16aa46ef06	\N	2026-07-12 13:32:30.590484	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 13:32:30.590484
508	SYSTEM	13	\N	\N	11cd9cdd-b7d8-45a1-b722-3225f17077c2	\N	2026-07-12 13:32:31.03156	{"reason": "", "sessionId": "6e5b6953-6407-baf5-1b43-8eabd48272f4"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 13:32:31.03156
509	ADMIN	1	Mustafa Assi	\N	83d8c359-9879-4a81-b909-d4c33bad245f	\N	2026-07-12 13:33:12.368096	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-12 13:33:12.368096
510	USER	1	\N	\N	da1d69f9-2136-40c7-aa00-0bd056b497f4	\N	2026-07-12 13:33:12.858972	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-12 13:33:12.858972
511	SYSTEM	1	\N	\N	6d5e320c-6123-4b73-97a0-ef55428d8815	\N	2026-07-12 13:33:13.595452	{"sessionId": "4c4ee936-45dd-3900-c915-15c3ec427c11"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 13:33:13.595452
512	ADMIN	1	\N	\N	42271e59-aa04-4d1c-8040-2a29b3a74900	\N	2026-07-12 13:33:23.946837	{}	ADMIN_VIEWED_RIDE	f	\N	\N	217	2026-07-12 13:33:23.946837
513	FLUTTER	\N	FLUTTER	\N	a136b175-9e1b-493f-b038-dec72e652ae5	\N	2026-07-12 13:33:44.27939	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	217	2026-07-12 13:33:44.27939
514	FLUTTER	\N	FLUTTER	\N	8d9b87a1-8c69-4d7d-b428-619a0e197a0c	\N	2026-07-12 13:33:44.353214	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 13:33:44.353214
515	FLUTTER	\N	FLUTTER	\N	76ae2c77-78c1-42ba-a370-726e6564f708	\N	2026-07-12 13:33:46.208651	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 13:33:46.208651
516	FLUTTER	\N	FLUTTER	\N	35cb8b4e-11d8-42c9-8bef-d14577384e8e	\N	2026-07-12 13:33:49.279028	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 13:33:49.279028
517	FLUTTER	\N	FLUTTER	\N	6697026c-da7d-4107-93d8-907bb15290fa	\N	2026-07-12 13:33:49.389551	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	217	2026-07-12 13:33:49.389551
518	FLUTTER	\N	FLUTTER	\N	cebb2c44-b37c-479b-94e7-3931d8ce1986	\N	2026-07-12 13:33:50.662183	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 13:33:50.662183
519	FLUTTER	\N	FLUTTER	\N	8d3ade9d-d5a9-4fce-af60-6056bd2e8550	\N	2026-07-12 13:33:50.673228	{"summary": "SETTINGS_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "SettingsScreen"}	SETTINGS_OPENED	f	\N	\N	217	2026-07-12 13:33:50.673228
520	FLUTTER	\N	FLUTTER	\N	b58d3c11-1557-4607-998a-05476760c54d	\N	2026-07-12 13:33:52.362761	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	217	2026-07-12 13:33:52.362761
521	FLUTTER	\N	FLUTTER	\N	73e7b375-125f-4ca6-84e4-9e031487f5db	\N	2026-07-12 13:33:52.362761	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	217	2026-07-12 13:33:52.362761
522	USER	1	\N	\N	46e00033-c56e-43d4-aafe-3365ccb96795	\N	2026-07-12 13:33:53.166618	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 13:33:53.166618
523	SYSTEM	1	\N	\N	9d721639-3ba6-440a-b2e6-3cbbe04b5e32	\N	2026-07-12 13:33:53.609987	{"reason": "", "sessionId": "4c4ee936-45dd-3900-c915-15c3ec427c11"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 13:33:53.609987
524	DRIVER	13	muasi	\N	4aaf33ab-6a68-45bc-a6b9-31ae8723fbef	\N	2026-07-12 14:50:53.908808	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-12 14:50:53.908808
525	ADMIN	1	Mustafa Assi	\N	5bd201df-c5a7-4698-ad66-8ce3874c6c17	\N	2026-07-12 14:52:26.590812	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-12 14:52:26.590812
526	USER	1	\N	\N	342b176b-fb1c-4718-a84b-d186931b6ace	\N	2026-07-12 14:52:27.861063	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-12 14:52:27.861063
527	SYSTEM	1	\N	\N	80d03fe5-92e6-40f0-8bcf-c115bd7d525a	\N	2026-07-12 14:52:29.491619	{"sessionId": "d185d80f-13a4-8f07-e9ed-687ece934383"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 14:52:29.491619
528	USER	1	\N	\N	e3a961a9-1439-4560-a908-db0b0ce92e1f	\N	2026-07-12 14:52:51.555307	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 14:52:51.555307
529	SYSTEM	1	\N	\N	ddcb6cc2-7258-41b1-a117-10e97235b5c4	\N	2026-07-12 14:52:52.006212	{"reason": "", "sessionId": "d185d80f-13a4-8f07-e9ed-687ece934383"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 14:52:52.006212
530	DRIVER	7	Mike Driver	\N	689446e0-a87a-40c6-a578-477934b108f5	\N	2026-07-12 14:53:27.497348	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 14:53:27.497348
531	USER	7	\N	\N	b865d34e-f8bb-4f0a-89d3-e38a6a27974b	\N	2026-07-12 14:53:28.229781	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-12 14:53:28.229781
532	SYSTEM	7	\N	\N	53d36f7c-0719-466f-b738-95938edcc53b	\N	2026-07-12 14:53:29.163508	{"sessionId": "dc8e1cbe-96e7-e28e-d3d4-8e97841346b2"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 14:53:29.163508
533	DRIVER	7	\N	\N	b6ad0bbc-54f3-45f6-b3dd-26f88d7f2f13	\N	2026-07-12 14:53:43.411991	{"category": "BUSINESS"}	DRIVER_WENT_ONLINE	f	\N	\N	\N	2026-07-12 14:53:43.411991
534	USER	7	\N	\N	7aa6b943-c27e-4a37-9574-df4594d88e2d	\N	2026-07-12 14:53:49.170508	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 14:53:49.170387
535	SYSTEM	7	\N	\N	06946b68-6855-4b34-8fa3-4a6d83718885	\N	2026-07-12 14:53:49.605465	{"reason": "", "sessionId": "dc8e1cbe-96e7-e28e-d3d4-8e97841346b2"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 14:53:49.605465
536	DRIVER	7	Mike Driver	\N	59f4733d-e59a-46b3-9b2e-790c82eb1832	\N	2026-07-12 14:53:56.525885	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 14:53:56.525885
537	USER	7	\N	\N	c157e287-c66d-47af-9c9d-79d361520b53	\N	2026-07-12 14:53:57.415811	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-12 14:53:57.415811
538	SYSTEM	7	\N	\N	5cbce23e-bf05-4a43-9ad6-8029a39582f8	\N	2026-07-12 14:53:58.229571	{"sessionId": "ad217dc2-3758-01c3-054c-5923b9b20c37"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 14:53:58.229571
539	USER	7	\N	\N	445f1e03-e698-4d0d-b35c-09ca0d7d1b8b	\N	2026-07-12 14:54:29.678902	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 14:54:29.678902
540	SYSTEM	7	\N	\N	634bbdb5-4bed-4267-b64e-da7e2aebf0f2	\N	2026-07-12 14:54:30.655873	{"reason": "", "sessionId": "ad217dc2-3758-01c3-054c-5923b9b20c37"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 14:54:30.655873
542	USER	6	\N	\N	1b5f16a9-3ae5-42aa-b2ce-3e78b0d6c201	\N	2026-07-12 14:54:35.562249	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-12 14:54:35.562249
545	SYSTEM	6	\N	\N	6cf2ce7d-2f8a-4369-b023-c5969757ffab	\N	2026-07-12 14:55:35.269928	{"reason": "", "sessionId": "84d1d13e-d3eb-cfbc-6cbf-819ab2735ae5"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 14:55:35.269928
541	RIDER	6	John Rider	\N	1578128c-3782-4f65-bda2-28b367103571	\N	2026-07-12 14:54:34.92228	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 14:54:34.92228
543	SYSTEM	6	\N	\N	ff2fc3d6-162d-46d7-98e5-5f5f3fde1ee0	\N	2026-07-12 14:54:36.134623	{"sessionId": "84d1d13e-d3eb-cfbc-6cbf-819ab2735ae5"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 14:54:36.134623
544	USER	6	\N	\N	c7b1043a-a6c0-44cd-8b2e-919bec8664e8	\N	2026-07-12 14:55:34.661033	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-12 14:55:34.661033
546	RIDER	6	John Rider	\N	21171132-b29f-4acc-8eed-1ad9e2d7485e	\N	2026-07-12 15:06:09.618484	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-12 15:06:09.618484
547	USER	6	\N	\N	6b405b3b-310b-4583-8adc-a70ae54a0751	\N	2026-07-12 15:06:10.247824	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-12 15:06:10.247824
548	SYSTEM	6	\N	\N	4c8ea9c8-29bd-4ddb-adc4-7d6b09b26ac5	\N	2026-07-12 15:06:10.963655	{"sessionId": "88926859-d1b7-6c16-e257-70257ea41321"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-12 15:06:10.963655
549	SYSTEM	6	\N	\N	a3a34401-91ff-4fd8-879a-894f29387248	\N	2026-07-12 15:06:21.410843	{"reason": "", "sessionId": "88926859-d1b7-6c16-e257-70257ea41321"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-12 15:06:21.410843
550	RIDER	6	John Rider	\N	4b4609b1-b5ce-4cb4-a8cc-c62374f489e2	\N	2026-07-13 09:14:35.157568	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 09:14:35.15657
551	SYSTEM	6	\N	\N	a73b2402-374d-4bc1-baeb-aaf267b5378c	\N	2026-07-13 09:14:37.75498	{"sessionId": "cc1a8f4c-42d3-7f39-6229-79f93ea5af3e"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 09:14:37.753983
552	RIDER	6	John Rider	\N	b1be8cf4-41c0-4617-8c94-8ba1269cd8da	\N	2026-07-13 09:20:07.87535	{"rideType": "ECONOMY", "estimatedFare": 2.91, "pickupAddress": "26.3983, 50.1448", "dropoffAddress": "26.3838, 50.1356", "estimatedDistance": 4.527, "estimatedDuration": 6}	RIDE_REQUESTED	f	\N	\N	219	2026-07-13 09:20:07.87535
553	FLUTTER	\N	FLUTTER	\N	7ffb515e-3a1c-420c-929a-06cc35f71e80	\N	2026-07-13 09:20:08.811332	{"summary": "Searching for nearby drivers", "category": "BUSINESS", "severity": "INFO", "screenName": "RiderSearchingDriver"}	DRIVER_SEARCH_STARTED	f	\N	\N	219	2026-07-13 09:20:08.811332
554	RIDER	6	John Rider	\N	51035e02-275b-464d-bb97-10c7b787f56b	\N	2026-07-13 09:23:39.838232	{"reason": "Rider cancelled search"}	RIDE_CANCELLED	f	\N	\N	219	2026-07-13 09:23:39.838232
555	FLUTTER	\N	FLUTTER	\N	07af551e-4521-47ba-90db-5427d7b0d0eb	\N	2026-07-13 09:23:40.289748	{"summary": "Navigated to Rider-home", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:23:40.289748
556	SYSTEM	6	\N	\N	f881300c-004a-462e-a90b-549aab589446	\N	2026-07-13 09:23:40.32632	{"reason": "", "sessionId": "cc1a8f4c-42d3-7f39-6229-79f93ea5af3e"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 09:23:40.32632
557	SYSTEM	6	\N	\N	b2779f6e-4a0c-40cc-a7fa-1913d0d3e7ea	\N	2026-07-13 09:23:41.351664	{"sessionId": "60ed633e-029a-abe0-997f-38e86adf476b"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 09:23:41.350147
558	FLUTTER	\N	FLUTTER	\N	e1d7110f-df92-4d2b-9df4-32fb06bb9574	\N	2026-07-13 09:23:45.923106	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	219	2026-07-13 09:23:45.923106
559	FLUTTER	\N	FLUTTER	\N	1f966052-be55-4fae-b262-27694ae4c91a	\N	2026-07-13 09:23:58.025753	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	219	2026-07-13 09:23:58.025753
560	FLUTTER	\N	FLUTTER	\N	92f672e5-6ad5-41cf-8fe9-4b4f618ed598	\N	2026-07-13 09:23:58.031243	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:23:58.031243
561	FLUTTER	\N	FLUTTER	\N	210103cf-c4d1-4091-9dda-3337c681e710	\N	2026-07-13 09:24:12.159555	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:24:12.159555
562	FLUTTER	\N	FLUTTER	\N	f6fa1d63-ff40-4cd7-8951-8bcb6b3c5ed9	\N	2026-07-13 09:24:12.162958	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	219	2026-07-13 09:24:12.162958
563	FLUTTER	\N	FLUTTER	\N	0d563633-8e63-4f48-ac9f-2ea66ff940f5	\N	2026-07-13 09:24:17.49004	{"summary": "User initiated ride request", "category": "BUSINESS", "severity": "INFO", "screenName": "RiderHomeScreen"}	RIDE_REQUEST_INITIATED	f	\N	\N	219	2026-07-13 09:24:17.49004
564	FLUTTER	\N	FLUTTER	\N	5a4ac572-b876-4ea1-afa0-16684698c60b	\N	2026-07-13 09:24:17.49004	{"summary": "Navigated to MaterialPageRoute<Map<String, dynamic>>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<Map<String, dynamic>>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:24:17.49004
565	FLUTTER	\N	FLUTTER	\N	e47fc5cf-9e3e-438b-9f3c-fb972db895d4	\N	2026-07-13 09:24:20.609353	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	219	2026-07-13 09:24:20.609353
566	FLUTTER	\N	FLUTTER	\N	2051aa74-08a3-4487-acf0-6a9664c38dab	\N	2026-07-13 09:24:20.622492	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:24:20.622492
567	USER	6	\N	\N	ecedd165-e92e-4289-a6b4-40e1cb07694a	\N	2026-07-13 09:24:22.263054	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 09:24:22.262056
568	SYSTEM	6	\N	\N	151dd81f-0dd9-4234-9d61-4a21bd3d17c9	\N	2026-07-13 09:24:22.779778	{"reason": "", "sessionId": "60ed633e-029a-abe0-997f-38e86adf476b"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 09:24:22.779065
569	ADMIN	1	Mustafa Assi	\N	77296c51-a0e4-4421-9cea-21c46c7361c6	\N	2026-07-13 09:24:47.015427	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-13 09:24:47.015427
570	FLUTTER	\N	FLUTTER	\N	d8c0e7a9-cbef-48a8-ae62-be0d516dce38	\N	2026-07-13 09:24:47.340496	{"summary": "Navigated to Rider-main", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:24:47.340496
571	FLUTTER	\N	FLUTTER	\N	1c5354ce-0306-4285-9e09-5e9afcde07de	\N	2026-07-13 09:24:47.353966	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	219	2026-07-13 09:24:47.353966
572	SYSTEM	1	\N	\N	7e0f2076-9a0e-4bfc-ab86-800efa3ca0a8	\N	2026-07-13 09:24:47.670551	{"sessionId": "c4ef5dfa-39c9-97b8-b901-6ab84ab53910"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 09:24:47.670551
573	FLUTTER	\N	FLUTTER	\N	9d266b84-3534-42f0-801a-1103d84137ac	\N	2026-07-13 09:24:48.135567	{"summary": "ADMIN_SCREEN_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminHomeScreen"}	ADMIN_SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:24:48.135567
574	FLUTTER	\N	FLUTTER	\N	57d6cc9b-6616-448c-9279-a5791d2de017	\N	2026-07-13 09:24:48.164825	{"summary": "ADMIN_SCREEN_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminDriverListScreen"}	ADMIN_SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:24:48.164825
575	FLUTTER	\N	FLUTTER	\N	c6664ab8-b86c-4a2d-9b6e-94a34c1cc7d9	\N	2026-07-13 09:24:51.057922	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminDriverListScreen"}	APP_RESUMED	f	\N	\N	219	2026-07-13 09:24:51.057922
576	FLUTTER	\N	FLUTTER	\N	dd9cdb71-6f32-437f-bacd-5da6aa6e48d0	\N	2026-07-13 09:25:22.377723	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:25:22.377723
577	FLUTTER	\N	FLUTTER	\N	94c24622-8c3e-4bbf-a767-9de0a604a233	\N	2026-07-13 09:25:30.206614	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:25:30.206614
580	FLUTTER	\N	FLUTTER	\N	8ffe6214-90de-4440-beb6-d17031da6abb	\N	2026-07-13 09:25:55.295008	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:25:55.295008
582	USER	1	\N	\N	22b81e53-40bb-494e-8c0f-425658531ebd	\N	2026-07-13 09:25:56.594562	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 09:25:56.594562
584	DRIVER	13	muasi	\N	a00a5c08-9374-4670-9c72-4e6d456df651	\N	2026-07-13 09:26:11.306009	{"email": "eng.mustafa83@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-13 09:26:11.306009
585	FLUTTER	\N	FLUTTER	\N	9d2054c3-23b1-45f2-a9b6-0156b2624e22	\N	2026-07-13 09:26:11.601921	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	219	2026-07-13 09:26:11.601921
588	SYSTEM	13	\N	\N	f2608695-3d79-4f47-a145-9cc1bb61a7b8	\N	2026-07-13 09:26:12.207219	{"sessionId": "3039cf2c-ffa8-3d94-bff8-602b0f211e57"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 09:26:12.207219
590	DRIVER	13	\N	\N	3f025f5f-9d0e-4f72-861c-90a28f7ac4dc	\N	2026-07-13 09:26:44.463533	{"category": "BUSINESS"}	DRIVER_WENT_ONLINE	f	\N	\N	\N	2026-07-13 09:26:44.463533
578	FLUTTER	\N	FLUTTER	\N	9c237b10-ce05-4307-a52c-5e13f8604c94	\N	2026-07-13 09:25:48.471736	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	219	2026-07-13 09:25:48.471736
579	FLUTTER	\N	FLUTTER	\N	d89aaac7-42c4-4586-81a6-07b97dcc854a	\N	2026-07-13 09:25:48.488182	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:25:48.488182
581	FLUTTER	\N	FLUTTER	\N	54573930-c41c-467c-a4e7-11e21e03d5fa	\N	2026-07-13 09:25:55.294009	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	219	2026-07-13 09:25:55.294009
583	SYSTEM	1	\N	\N	47c56e04-bff9-4e70-9b42-392de4ea8301	\N	2026-07-13 09:25:57.102552	{"reason": "", "sessionId": "c4ef5dfa-39c9-97b8-b901-6ab84ab53910"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 09:25:57.102552
586	FLUTTER	\N	FLUTTER	\N	7a94486d-9657-4797-b7ea-ee0c45a4f0ce	\N	2026-07-13 09:26:11.634009	{"summary": "Navigated to Driver-home", "category": "FRONTEND", "severity": "INFO", "screenName": "Driver-home"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:26:11.634009
587	FLUTTER	\N	FLUTTER	\N	f8ee5af5-8784-4da3-a09c-7b941da6586b	\N	2026-07-13 09:26:11.919332	{"summary": "Driver home screen opened", "category": "FRONTEND", "severity": "INFO", "screenName": "DriverHomeScreen"}	DRIVER_HOME_OPENED	f	\N	\N	219	2026-07-13 09:26:11.919332
589	FLUTTER	\N	FLUTTER	\N	e54a828a-a95a-4f5d-8864-6fdac2be27b0	\N	2026-07-13 09:26:13.455697	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "DriverHomeScreen"}	APP_RESUMED	f	\N	\N	219	2026-07-13 09:26:13.455697
591	FLUTTER	\N	FLUTTER	\N	1899e516-c852-4c95-9024-b7a5c8658e70	\N	2026-07-13 09:26:44.721612	{"summary": "Driver went online", "category": "BUSINESS", "severity": "INFO", "screenName": "DriverHomeScreen"}	DRIVER_WENT_ONLINE	f	\N	\N	219	2026-07-13 09:26:44.721612
592	FLUTTER	\N	FLUTTER	\N	18a850c6-c1b3-459b-b4dc-3531ad3dec48	\N	2026-07-13 09:27:18.518915	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:27:18.518915
593	FLUTTER	\N	FLUTTER	\N	0ccb702a-575f-4d3b-941e-cd59297c0db0	\N	2026-07-13 09:27:20.691166	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:27:20.691166
594	FLUTTER	\N	FLUTTER	\N	2486c7a2-72bc-4d51-8f04-391a4523b643	\N	2026-07-13 09:27:54.906238	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:27:54.906238
595	FLUTTER	\N	FLUTTER	\N	82eb2214-ad39-4071-9d1c-ce5f796056cf	\N	2026-07-13 09:32:11.933337	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	APP_RESUMED	f	\N	\N	219	2026-07-13 09:32:11.933337
596	FLUTTER	\N	FLUTTER	\N	b1cd159b-bb8f-4d4a-b527-0621ab02ad8a	\N	2026-07-13 09:32:17.872977	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	APP_RESUMED	f	\N	\N	219	2026-07-13 09:32:17.872977
597	FLUTTER	\N	FLUTTER	\N	7a8d5024-e358-43d8-9a37-6e3c09c1aebc	\N	2026-07-13 09:32:35.549107	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	APP_RESUMED	f	\N	\N	219	2026-07-13 09:32:35.549107
598	FLUTTER	\N	FLUTTER	\N	4f84b0f6-1841-4195-9a98-80c6d0664beb	\N	2026-07-13 09:34:34.64899	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	APP_RESUMED	f	\N	\N	219	2026-07-13 09:34:34.64899
599	SYSTEM	13	\N	\N	0a8a50f9-11b5-412a-8778-7523fc1d38da	\N	2026-07-13 09:49:52.078444	{"reason": "Inactive for 10 minutes", "category": "SCHEDULER"}	DRIVER_AUTO_OFFLINE	f	\N	\N	\N	2026-07-13 09:49:52.077934
600	RIDER	6	John Rider	\N	4452dafc-b8af-4899-a10f-7dcab2ccc36f	\N	2026-07-13 09:49:58.435185	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 09:49:58.435185
601	FLUTTER	\N	FLUTTER	\N	a72d699e-76e2-4cb9-98e1-ed1d3a4b578f	\N	2026-07-13 09:49:58.899502	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	219	2026-07-13 09:49:58.899502
602	FLUTTER	\N	FLUTTER	\N	e99b8187-3bfe-4a21-9e9a-6414e095d69e	\N	2026-07-13 09:49:58.916466	{"summary": "Navigated to Rider-main", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:49:58.916466
603	SYSTEM	6	\N	\N	2ed013ec-3ce0-443e-be3b-f1aa863a2258	\N	2026-07-13 09:49:59.146063	{"sessionId": "a718c1e5-9ac5-bfd8-8ea4-d45e3a2efdf1"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 09:49:59.146063
604	FLUTTER	\N	FLUTTER	\N	77890c4c-7207-4650-9111-50a2d437d584	\N	2026-07-13 09:50:03.076019	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:50:03.076019
605	RIDER	6	John Rider	\N	99edd74b-bb93-4d09-a022-e68e70b07bce	\N	2026-07-13 09:50:10.538249	{"rideType": "ECONOMY", "estimatedFare": 2.91, "pickupAddress": "26.3983, 50.1448", "dropoffAddress": "26.3838, 50.1356", "estimatedDistance": 4.527, "estimatedDuration": 6}	RIDE_REQUESTED	f	\N	\N	220	2026-07-13 09:50:10.538249
606	FLUTTER	\N	FLUTTER	\N	bd401dd4-d401-4b64-9e3b-9a9172a974ad	\N	2026-07-13 09:50:10.812878	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	219	2026-07-13 09:50:10.812878
607	FLUTTER	\N	FLUTTER	\N	a97c6b6a-fe0b-4d65-9c77-0fa36b8307be	\N	2026-07-13 09:50:10.914722	{"summary": "Searching for nearby drivers", "category": "BUSINESS", "severity": "INFO", "screenName": "RiderSearchingDriver"}	DRIVER_SEARCH_STARTED	f	\N	\N	220	2026-07-13 09:50:10.914722
608	SYSTEM	\N	RideScheduler	\N	277d64b0-89c4-458d-b9e2-035a2701376d	\N	2026-07-13 09:51:11.843509	{"detail": "No driver found in 60 seconds", "category": "SCHEDULER"}	SCHEDULED_TIMEOUT_NOTIFICATION	f	\N	\N	220	2026-07-13 09:51:11.843509
609	FLUTTER	\N	FLUTTER	\N	3e6462d3-9b51-4016-a6b1-604b244a9ac2	\N	2026-07-13 09:51:12.131585	{"outcome": "displayed", "summary": "Dialog", "category": "UI", "dialogText": "No drivers available nearby", "screenName": "RiderSearchingDriver", "triggerReason": "60_second_search_timeout", "uiElementType": "Dialog", "availableButtons": "Cancel, Continue"}	UI_DIALOG_SHOWN	f	\N	\N	220	2026-07-13 09:51:12.131585
610	FLUTTER	\N	FLUTTER	\N	58ba1175-47ec-4378-8838-a8fb2b50005c	\N	2026-07-13 09:51:12.131585	{"summary": "No driver found after 60 seconds timeout", "category": "BUSINESS", "severity": "INFO", "screenName": "RiderSearchingDriver"}	SEARCH_TIMEOUT	f	\N	\N	220	2026-07-13 09:51:12.131585
611	FLUTTER	\N	FLUTTER	\N	deba8bd1-8544-4a4d-a18b-fead6f143edb	\N	2026-07-13 09:51:12.237779	{"summary": "Navigated to DialogRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "DialogRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 09:51:12.237779
612	FLUTTER	\N	FLUTTER	\N	b609904d-485b-4093-b110-4192ca5a2874	\N	2026-07-13 09:51:16.86238	{"outcome": "resolved", "summary": "Dialog", "category": "UI", "dialogText": "No drivers available nearby", "screenName": "MaterialPageRoute<dynamic>", "userChoice": "cancel", "uiElementType": "Dialog"}	UI_DIALOG_RESULT	f	\N	\N	220	2026-07-13 09:51:16.86238
613	RIDER	6	John Rider	\N	5c478995-b605-432d-a799-0791b049af53	\N	2026-07-13 09:51:17.118224	{"reason": "Rider cancelled search"}	RIDE_CANCELLED	f	\N	\N	220	2026-07-13 09:51:17.118224
614	FLUTTER	\N	FLUTTER	\N	421f8bc4-17d4-4a24-9dbe-243752d66868	\N	2026-07-13 09:51:17.367117	{"summary": "Navigated to Rider-home", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 09:51:17.367117
615	SYSTEM	6	\N	\N	f2854226-deac-49b0-a668-92a31c44f30c	\N	2026-07-13 09:51:17.397807	{"reason": "", "sessionId": "a718c1e5-9ac5-bfd8-8ea4-d45e3a2efdf1"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 09:51:17.397807
617	FLUTTER	\N	FLUTTER	\N	9372e39d-22e3-4fad-9e2a-149d3f5156b9	\N	2026-07-13 09:52:27.798041	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	220	2026-07-13 09:52:27.798041
618	FLUTTER	\N	FLUTTER	\N	571243b4-f593-4d84-a25a-e8ecf69949cf	\N	2026-07-13 09:52:49.880702	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	220	2026-07-13 09:52:49.880702
619	FLUTTER	\N	FLUTTER	\N	2894e9d4-9ba1-4b4a-b124-5e07149aab2d	\N	2026-07-13 09:54:10.180981	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	220	2026-07-13 09:54:10.180981
620	FLUTTER	\N	FLUTTER	\N	0fd5ee39-4202-45a5-aa27-d30a9753f450	\N	2026-07-13 09:54:30.195643	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	220	2026-07-13 09:54:30.195643
621	FLUTTER	\N	FLUTTER	\N	35580c44-6a36-4d4f-a497-c42837fac94e	\N	2026-07-13 10:00:31.144582	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	220	2026-07-13 10:00:31.144582
622	FLUTTER	\N	FLUTTER	\N	d9eff206-3057-4fa0-a2eb-e579d9b091ac	\N	2026-07-13 10:00:32.858899	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	220	2026-07-13 10:00:32.858899
623	FLUTTER	\N	FLUTTER	\N	db15e14b-1dd1-4ff3-a42e-050d77fbfbe2	\N	2026-07-13 10:00:33.14891	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	220	2026-07-13 10:00:33.14891
624	FLUTTER	\N	FLUTTER	\N	38eb7c2e-cfae-4897-a9f0-285f4c5ff830	\N	2026-07-13 10:00:45.385588	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 10:00:45.385588
625	FLUTTER	\N	FLUTTER	\N	a2a03b27-04de-493f-901a-eec179044e18	\N	2026-07-13 10:00:45.554917	{"summary": "SETTINGS_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "SettingsScreen"}	SETTINGS_OPENED	f	\N	\N	220	2026-07-13 10:00:45.554917
626	FLUTTER	\N	FLUTTER	\N	68f66a3c-db5e-4c7b-a2ec-acfb5fd48b78	\N	2026-07-13 10:00:49.035221	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	220	2026-07-13 10:00:49.035221
627	FLUTTER	\N	FLUTTER	\N	4222fa7f-fbd2-417c-9fde-3202a3375e76	\N	2026-07-13 10:00:49.041422	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 10:00:49.041422
628	USER	6	\N	\N	bae44504-19e3-44e2-b7f7-1f0a90d437ea	\N	2026-07-13 10:00:49.943289	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 10:00:49.943289
629	SYSTEM	6	\N	\N	ff82ddcf-117d-45c1-bc80-c419cfbc281b	\N	2026-07-13 10:00:50.448494	{"reason": "", "sessionId": "4788760f-b523-eef1-6d05-56510f670986"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:00:50.448494
631	FLUTTER	\N	FLUTTER	\N	563ad251-485b-4e07-b4ff-23da79a33e6f	\N	2026-07-13 10:00:55.170243	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	220	2026-07-13 10:00:55.170243
633	SYSTEM	6	\N	\N	61d19499-bf93-47af-ba54-494134e6f46a	\N	2026-07-13 10:00:55.667634	{"sessionId": "2e38ff37-8cc7-d4d3-f437-a113bee38e12"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:00:55.667634
616	SYSTEM	6	\N	\N	bca53f6f-6ae3-40b1-bceb-70aa93a261a1	\N	2026-07-13 09:51:17.850851	{"sessionId": "4788760f-b523-eef1-6d05-56510f670986"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 09:51:17.849317
630	RIDER	6	John Rider	\N	0c830fea-430e-4a0e-8909-85829e4104ed	\N	2026-07-13 10:00:54.886649	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:00:54.886649
632	FLUTTER	\N	FLUTTER	\N	36c89465-99e1-429c-a1dd-376d7833a7da	\N	2026-07-13 10:00:55.172756	{"summary": "Navigated to Rider-main", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 10:00:55.171758
634	FLUTTER	\N	FLUTTER	\N	6acd07f1-5c5c-4ce2-9a3f-fd12e016ab48	\N	2026-07-13 10:01:25.088691	{"summary": "User initiated ride request", "category": "BUSINESS", "severity": "INFO", "screenName": "RiderHomeScreen"}	RIDE_REQUEST_INITIATED	f	\N	\N	220	2026-07-13 10:01:25.088691
635	FLUTTER	\N	FLUTTER	\N	658dcd90-4bf1-4772-be05-b95813af5b36	\N	2026-07-13 10:01:25.10933	{"summary": "Navigated to MaterialPageRoute<Map<String, dynamic>>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<Map<String, dynamic>>"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 10:01:25.10933
636	FLUTTER	\N	FLUTTER	\N	9b3b4921-7105-475e-bdd0-7415d32efcd3	\N	2026-07-13 10:01:27.970533	{"summary": "Navigated to MaterialPageRoute<Map<String, dynamic>>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<Map<String, dynamic>>"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 10:01:27.970533
637	FLUTTER	\N	FLUTTER	\N	9b244668-89f0-48f4-9c63-8f0c58864cd1	\N	2026-07-13 10:01:27.972527	{"summary": "User initiated ride request", "category": "BUSINESS", "severity": "INFO", "screenName": "RiderHomeScreen"}	RIDE_REQUEST_INITIATED	f	\N	\N	220	2026-07-13 10:01:27.971531
638	FLUTTER	\N	FLUTTER	\N	a0f63bff-b05b-4cd7-8edf-2a5ff26fcc78	\N	2026-07-13 10:01:32.159095	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 10:01:32.159095
639	RIDER	6	John Rider	\N	f44dbedd-1a3b-4c1d-8ea0-e97d9a6723b2	\N	2026-07-13 10:01:38.872232	{"rideType": "ECONOMY", "estimatedFare": 2.12, "pickupAddress": "26.3980, 50.1454", "dropoffAddress": "26.3942, 50.1424", "estimatedDistance": 0.623, "estimatedDuration": 2}	RIDE_REQUESTED	f	\N	\N	221	2026-07-13 10:01:38.872232
640	FLUTTER	\N	FLUTTER	\N	127d0ecc-8241-460b-9caa-343f37972078	\N	2026-07-13 10:01:39.157541	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	220	2026-07-13 10:01:39.157541
641	FLUTTER	\N	FLUTTER	\N	8cdab657-4e62-493c-a03f-dd347d431a5c	\N	2026-07-13 10:01:39.230877	{"summary": "Searching for nearby drivers", "category": "BUSINESS", "severity": "INFO", "screenName": "RiderSearchingDriver"}	DRIVER_SEARCH_STARTED	f	\N	\N	221	2026-07-13 10:01:39.230877
642	FLUTTER	\N	FLUTTER	\N	9885f1b7-4eef-4103-9802-31a0dd4f5ce7	\N	2026-07-13 10:01:47.120071	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderSearchingDriver"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:01:47.120071
643	RIDER	6	John Rider	\N	e5611688-78c1-406a-ba50-42bff64867ee	\N	2026-07-13 10:01:48.292556	{"reason": "Rider cancelled search"}	RIDE_CANCELLED	f	\N	\N	221	2026-07-13 10:01:48.292556
644	FLUTTER	\N	FLUTTER	\N	d8ec204b-c17a-45da-893d-6acaed1155ec	\N	2026-07-13 10:01:48.533892	{"summary": "Navigated to Rider-home", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-home"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:01:48.533892
645	SYSTEM	6	\N	\N	2d8f19c7-3178-455f-a42a-beb8084daeef	\N	2026-07-13 10:01:48.588467	{"reason": "", "sessionId": "2e38ff37-8cc7-d4d3-f437-a113bee38e12"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:01:48.588467
646	SYSTEM	6	\N	\N	c28d4b74-2568-4d00-b53f-db62455cbc68	\N	2026-07-13 10:01:49.140732	{"sessionId": "5dee032a-c6ea-55e1-1209-0faaa85bf554"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:01:49.140732
647	FLUTTER	\N	FLUTTER	\N	da1d4f13-dad6-42c6-9363-cbdbaff69d2a	\N	2026-07-13 10:01:55.428691	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:01:55.428691
648	FLUTTER	\N	FLUTTER	\N	eb472527-834b-4f59-9c3d-dfc4cbd35e47	\N	2026-07-13 10:01:56.778583	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:01:56.777581
649	FLUTTER	\N	FLUTTER	\N	8cceb3f0-67cc-4ecf-829b-fe54743bc806	\N	2026-07-13 10:02:27.574843	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:02:27.574843
650	FLUTTER	\N	FLUTTER	\N	b9363628-0b84-40e3-ac57-85cf97718af5	\N	2026-07-13 10:02:28.810413	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	221	2026-07-13 10:02:28.810413
651	FLUTTER	\N	FLUTTER	\N	1a64fe66-5696-4fde-be5f-22b980519538	\N	2026-07-13 10:02:28.834762	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:02:28.834762
652	USER	6	\N	\N	3eb65a29-2d9f-4616-b44e-f5cab6e45e5f	\N	2026-07-13 10:02:29.722667	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 10:02:29.722667
653	SYSTEM	6	\N	\N	23ac4523-7d2e-411f-9577-ea0d62cf60d2	\N	2026-07-13 10:02:30.323176	{"reason": "", "sessionId": "5dee032a-c6ea-55e1-1209-0faaa85bf554"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:02:30.323176
654	RIDER	6	John Rider	\N	828455aa-d05b-4939-8b31-e020e40501a6	\N	2026-07-13 10:02:34.325785	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:02:34.325785
655	FLUTTER	\N	FLUTTER	\N	5c70e6c2-5589-42d8-8839-fc7424cff73b	\N	2026-07-13 10:02:34.58362	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	221	2026-07-13 10:02:34.58362
656	FLUTTER	\N	FLUTTER	\N	ab317a3d-29bf-4875-b73e-6184907f9c7f	\N	2026-07-13 10:02:34.589921	{"summary": "Navigated to Rider-main", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:02:34.589334
657	SYSTEM	6	\N	\N	aa984db2-0b57-4c86-b1c0-e8356a420502	\N	2026-07-13 10:02:35.059058	{"sessionId": "4592c1c6-eaf6-7ebc-d854-c0e7d4d691db"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:02:35.059058
658	FLUTTER	\N	FLUTTER	\N	80193d9f-4b74-4b42-8ebd-404e26349d8a	\N	2026-07-13 10:02:44.16133	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "RiderHomeScreen"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:02:44.16133
659	FLUTTER	\N	FLUTTER	\N	bf469ef0-c07e-49c3-a059-a0012c126ccb	\N	2026-07-13 10:02:46.624964	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	221	2026-07-13 10:02:46.624964
660	FLUTTER	\N	FLUTTER	\N	b4b155c9-dd88-4c2c-9f30-f17e669c1057	\N	2026-07-13 10:02:46.638231	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:02:46.638231
661	USER	6	\N	\N	bbfad99b-db6f-4e18-a32e-64332b9bb768	\N	2026-07-13 10:02:47.827348	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 10:02:47.827348
662	SYSTEM	6	\N	\N	8c418bbc-e20d-4779-844c-0f40c4b08b82	\N	2026-07-13 10:02:48.289726	{"reason": "", "sessionId": "4592c1c6-eaf6-7ebc-d854-c0e7d4d691db"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:02:48.289726
663	DRIVER	7	Mike Driver	\N	59f59c6f-3714-48fc-ac9b-8dd52b8c82a4	\N	2026-07-13 10:02:50.906089	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:02:50.906089
664	FLUTTER	\N	FLUTTER	\N	1dd9ffc9-e08a-41d6-add6-d13115856ec5	\N	2026-07-13 10:02:51.171199	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	221	2026-07-13 10:02:51.171199
667	FLUTTER	\N	FLUTTER	\N	cb5108dc-43b6-4009-8b34-b96794f07b35	\N	2026-07-13 10:02:51.453186	{"summary": "Driver home screen opened", "category": "FRONTEND", "severity": "INFO", "screenName": "DriverHomeScreen"}	DRIVER_HOME_OPENED	f	\N	\N	221	2026-07-13 10:02:51.453186
668	FLUTTER	\N	FLUTTER	\N	eb519de7-9350-4b17-ae2a-b29808d13655	\N	2026-07-13 10:03:00.669344	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:03:00.669344
669	USER	7	\N	\N	25eba538-f10a-4eb0-832f-74ce4cec3ccd	\N	2026-07-13 10:03:03.738673	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 10:03:03.738673
670	SYSTEM	7	\N	\N	61e0c789-c554-4cb9-8a16-023f91a07c13	\N	2026-07-13 10:03:04.200513	{"reason": "", "sessionId": "7c8c929d-01fd-f189-4c4f-3367332815f8"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:03:04.200513
671	ADMIN	1	Mustafa Assi	\N	664801c0-71f3-4540-9d4d-dac7f43439bd	\N	2026-07-13 10:03:17.397049	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:03:17.397049
672	FLUTTER	\N	FLUTTER	\N	9b2d6721-a699-4bd3-9046-4b5a80e445d8	\N	2026-07-13 10:03:17.678309	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	221	2026-07-13 10:03:17.678309
676	FLUTTER	\N	FLUTTER	\N	c70881e5-d0db-4746-8330-0ae71bae932e	\N	2026-07-13 10:03:18.275418	{"summary": "ADMIN_SCREEN_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminHomeScreen"}	ADMIN_SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:03:18.275418
677	FLUTTER	\N	FLUTTER	\N	886d3ca5-a36d-4921-9211-dee72bb7b68e	\N	2026-07-13 10:03:20.261392	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminDriverListScreen"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:03:20.261392
678	FLUTTER	\N	FLUTTER	\N	44cba406-9837-44c7-a75f-e036c184bb42	\N	2026-07-13 10:03:28.272013	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:03:28.272013
694	ADMIN	1	Mustafa	\N	01d6bf83-3191-47a2-a91f-10c555ac1b43	\N	2026-07-13 10:06:13.492309	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:06:13.492309
696	FLUTTER	\N	FLUTTER	\N	fb48702f-6baf-4692-8351-677213442aff	\N	2026-07-13 10:06:13.777643	{"summary": "Navigated to Rider-main", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:06:13.777643
702	FLUTTER	\N	FLUTTER	\N	aea477bb-caba-40b1-a54d-21fcf6484785	\N	2026-07-13 10:06:36.616874	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	221	2026-07-13 10:06:36.616874
703	FLUTTER	\N	FLUTTER	\N	19138791-3568-4053-bebf-b2736bbba7bc	\N	2026-07-13 10:06:36.627607	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:06:36.627607
705	FLUTTER	\N	FLUTTER	\N	6db64807-bd26-4cf1-a3b0-0463457dd94c	\N	2026-07-13 10:06:37.784253	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	221	2026-07-13 10:06:37.784253
707	FLUTTER	\N	FLUTTER	\N	5b0eaa99-cf5e-4101-ae7c-28d15b2a7b2c	\N	2026-07-13 10:07:08.537842	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	221	2026-07-13 10:07:08.537842
665	FLUTTER	\N	FLUTTER	\N	2c0a3f73-e66b-41fe-9705-738d74abf461	\N	2026-07-13 10:02:51.178642	{"summary": "Navigated to Driver-home", "category": "FRONTEND", "severity": "INFO", "screenName": "Driver-home"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:02:51.178642
666	SYSTEM	7	\N	\N	f201f13b-7b11-4886-af22-8b5acabc8593	\N	2026-07-13 10:02:51.448676	{"sessionId": "7c8c929d-01fd-f189-4c4f-3367332815f8"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:02:51.448676
673	FLUTTER	\N	FLUTTER	\N	a4f5bf01-a1ff-44b3-bb87-eb2f69b31023	\N	2026-07-13 10:03:17.692284	{"summary": "Navigated to Rider-main", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:03:17.692284
674	SYSTEM	1	\N	\N	b2decdd6-ad65-49c0-8b5b-be81921b34cc	\N	2026-07-13 10:03:17.951267	{"sessionId": "aeed8115-7a83-7c5a-7d06-a4822b48f177"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:03:17.951267
675	FLUTTER	\N	FLUTTER	\N	bd1f0172-e73f-4c05-9d7b-cfc86f19a1a2	\N	2026-07-13 10:03:18.180145	{"summary": "ADMIN_SCREEN_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminDriverListScreen"}	ADMIN_SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:03:18.180145
679	ADMIN	1	\N	\N	8639c899-ecbd-41fb-a1da-d23a6d271cbb	\N	2026-07-13 10:03:28.740125	{}	ADMIN_VIEWED_RIDE	f	\N	\N	221	2026-07-13 10:03:28.740125
680	FLUTTER	\N	FLUTTER	\N	54793199-d0a4-4d40-8179-581ab2a3b8e9	\N	2026-07-13 10:04:20.836582	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:04:20.836582
681	FLUTTER	\N	FLUTTER	\N	3526ed2b-2eb8-40d2-9ff1-77c864b99955	\N	2026-07-13 10:04:39.188835	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:04:39.188835
682	FLUTTER	\N	FLUTTER	\N	cb4debd4-702f-4d72-a86e-7f6f02646b51	\N	2026-07-13 10:04:40.205544	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:04:40.205544
683	FLUTTER	\N	FLUTTER	\N	2b335272-fb25-45e8-a930-ec48a39b28b0	\N	2026-07-13 10:04:48.34444	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:04:48.34444
684	FLUTTER	\N	FLUTTER	\N	37cd5465-7d11-42bd-a79a-6ce3f7458330	\N	2026-07-13 10:05:01.209242	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:05:01.209242
685	FLUTTER	\N	FLUTTER	\N	bff7030b-4f99-4358-b6ac-e0bc49d7e76d	\N	2026-07-13 10:05:35.982457	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:05:35.982457
686	FLUTTER	\N	FLUTTER	\N	8473e417-94b6-44d2-acf2-a3ab7028aea1	\N	2026-07-13 10:05:38.439289	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:05:38.439289
687	FLUTTER	\N	FLUTTER	\N	182ee668-f5ce-4497-b8da-b17026c5761e	\N	2026-07-13 10:05:42.105819	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:05:42.105819
688	FLUTTER	\N	FLUTTER	\N	c374f7a8-fc0a-4b76-948f-6fd642814801	\N	2026-07-13 10:05:45.343562	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:05:45.343562
689	FLUTTER	\N	FLUTTER	\N	64fb6eff-6ed5-4d1f-9a2d-9498902855d0	\N	2026-07-13 10:05:48.405478	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:05:48.405478
690	FLUTTER	\N	FLUTTER	\N	483c6050-6667-47cb-b3ae-7705b35f08d5	\N	2026-07-13 10:06:02.016806	{"summary": "Menu bottom sheet displayed", "category": "UI", "severity": "INFO", "sheetType": "menu", "screenName": "RiderHomeScreen"}	MODAL_BOTTOM_SHEET_SHOWN	f	\N	\N	221	2026-07-13 10:06:02.016806
691	FLUTTER	\N	FLUTTER	\N	139bba3b-34f1-4cd3-873d-407ce324753f	\N	2026-07-13 10:06:02.031885	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:06:02.031885
692	USER	1	\N	\N	593b5832-fe4b-45c6-8222-3f781bbe19d2	\N	2026-07-13 10:06:02.981745	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 10:06:02.981745
693	SYSTEM	1	\N	\N	040f2f72-0c9b-4ffa-8efe-62f9859665b9	\N	2026-07-13 10:06:03.505256	{"reason": "", "sessionId": "aeed8115-7a83-7c5a-7d06-a4822b48f177"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:06:03.505256
695	FLUTTER	\N	FLUTTER	\N	76807541-aebb-42fb-94ae-fed5796a7dd6	\N	2026-07-13 10:06:13.777643	{"summary": "User logged in successfully", "category": "BUSINESS", "severity": "INFO", "screenName": "AuthScreen"}	LOGIN_SUCCESS	f	\N	\N	221	2026-07-13 10:06:13.777643
697	FLUTTER	\N	FLUTTER	\N	034534b0-c247-4770-8f17-eee847847bd6	\N	2026-07-13 10:06:14.187328	{"summary": "ADMIN_SCREEN_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminHomeScreen"}	ADMIN_SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:06:14.187328
698	FLUTTER	\N	FLUTTER	\N	8b1c33e3-4ee1-44d7-829e-84ae9de58f7b	\N	2026-07-13 10:06:14.200813	{"summary": "ADMIN_SCREEN_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "AdminDriverListScreen"}	ADMIN_SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:06:14.200813
699	SYSTEM	1	\N	\N	f1b1ec29-f685-401b-b992-73b1e26ff01f	\N	2026-07-13 10:06:14.221041	{"sessionId": "d19075e9-4cce-b283-d771-2a4a52535b6a"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:06:14.221041
700	FLUTTER	\N	FLUTTER	\N	d56e36e5-2a55-4553-a441-225e13da4873	\N	2026-07-13 10:06:18.818981	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:06:18.818981
701	FLUTTER	\N	FLUTTER	\N	f1f41d21-81ca-4ab7-ac9e-305f20af6357	\N	2026-07-13 10:06:30.56044	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:06:30.56044
704	FLUTTER	\N	FLUTTER	\N	a5d53c10-0291-4b1c-a937-cdd21b7ad704	\N	2026-07-13 10:06:37.780247	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:06:37.780247
706	FLUTTER	\N	FLUTTER	\N	6993e39d-3d1f-4f6d-af06-b20923e47c2b	\N	2026-07-13 10:07:08.536847	{"summary": "Navigated to ModalBottomSheetRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:07:08.536847
708	FLUTTER	\N	FLUTTER	\N	3f07da84-5e52-4651-b1a6-8b3f4a07f062	\N	2026-07-13 10:07:17.357616	{"summary": "Navigated to MaterialPageRoute<dynamic>", "category": "FRONTEND", "severity": "INFO", "screenName": "MaterialPageRoute<dynamic>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:07:17.357616
709	FLUTTER	\N	FLUTTER	\N	fd0b9c45-c7ad-4f10-9647-cb1e0247f944	\N	2026-07-13 10:07:17.473181	{"summary": "SETTINGS_OPENED", "category": "FRONTEND", "severity": "INFO", "screenName": "SettingsScreen"}	SETTINGS_OPENED	f	\N	\N	221	2026-07-13 10:07:17.473181
710	FLUTTER	\N	FLUTTER	\N	5974c30c-2b08-47f6-ad71-fec191863ce5	\N	2026-07-13 10:08:29.192493	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:08:29.192493
711	FLUTTER	\N	FLUTTER	\N	d0ee2933-feb4-41d2-8ea8-8b96fe453de2	\N	2026-07-13 10:08:45.570022	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "Rider-main"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:08:45.570022
712	FLUTTER	\N	FLUTTER	\N	9e2e944f-7305-402b-ab7b-c1006ae02103	\N	2026-07-13 10:08:51.349313	{"summary": "Navigated to ModalBottomSheetRoute<bool>", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	SCREEN_OPENED	f	\N	\N	221	2026-07-13 10:08:51.349313
713	FLUTTER	\N	FLUTTER	\N	56b4c2fe-288d-4b79-9ee4-e9c4aa6ffb00	\N	2026-07-13 10:08:59.462146	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:08:59.462146
714	FLUTTER	\N	FLUTTER	\N	13da50a2-b390-4d8b-a027-fa5911a6639f	\N	2026-07-13 10:10:00.98079	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:10:00.98079
715	FLUTTER	\N	FLUTTER	\N	0e8c65e3-ca36-4f07-9385-10a3076914d3	\N	2026-07-13 10:10:14.853219	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:10:14.853219
716	FLUTTER	\N	FLUTTER	\N	c96615c9-5bbf-4334-8239-641501a4c38b	\N	2026-07-13 10:10:20.579245	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:10:20.579245
717	FLUTTER	\N	FLUTTER	\N	d859de40-b3df-4129-baa4-a0b1d3850afe	\N	2026-07-13 10:10:33.689595	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:10:33.689595
718	FLUTTER	\N	FLUTTER	\N	f25e0c5b-ea81-4484-bc6e-9fda8282a812	\N	2026-07-13 10:11:02.755103	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:11:02.755103
719	FLUTTER	\N	FLUTTER	\N	900da002-8848-4832-bdcb-a9b32240a923	\N	2026-07-13 10:11:33.845557	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:11:33.845557
720	FLUTTER	\N	FLUTTER	\N	e5fa8757-17fd-4390-9f68-e7ba09fccad9	\N	2026-07-13 10:13:18.832261	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:13:18.832261
721	FLUTTER	\N	FLUTTER	\N	86cec256-0e80-4254-a640-3cfe459023c4	\N	2026-07-13 10:13:19.901564	{"summary": "Application resumed from background", "category": "FRONTEND", "severity": "INFO", "screenName": "ModalBottomSheetRoute<bool>"}	APP_RESUMED	f	\N	\N	221	2026-07-13 10:13:19.901564
722	RIDER	6	John Rider	\N	7f3744dc-ce26-4aed-8bc5-751a91613265	\N	2026-07-13 10:22:03.334211	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:22:03.333177
723	SYSTEM	6	\N	\N	513350dd-79b6-4f24-b8bd-3a4ff23d3b24	\N	2026-07-13 10:22:04.68284	{"sessionId": "829e3016-dc54-016b-7a5f-9def53cda4fb"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:22:04.68284
724	USER	6	\N	\N	e61ae0e9-32a0-4987-b519-778665659b68	\N	2026-07-13 10:35:24.913263	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 10:35:24.913263
725	SYSTEM	6	\N	\N	0ba65a11-beb9-4faf-a011-6a6975aaf931	\N	2026-07-13 10:35:25.584692	{"reason": "", "sessionId": "829e3016-dc54-016b-7a5f-9def53cda4fb"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:35:25.584692
726	RIDER	6	John Rider	\N	b838ed34-414c-4f68-9bd8-1a082cfbd19a	\N	2026-07-13 10:35:48.516676	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:35:48.516676
727	SYSTEM	6	\N	\N	78aeb102-8525-47f7-9cd8-c2c67f506f39	\N	2026-07-13 10:35:49.191701	{"sessionId": "86b00270-889f-227b-dc3c-f980ebab0536"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:35:49.191701
728	SYSTEM	6	\N	\N	685488f8-ac7f-4d72-8437-85cc0539599d	\N	2026-07-13 10:41:51.561716	{"sessionId": "a68969a5-0cdd-ce12-ab95-0305abfb4beb"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:41:51.561716
729	SYSTEM	6	\N	\N	5d02e643-e773-4647-a6c3-ddd062b0b89c	\N	2026-07-13 10:41:53.03749	{"reason": "", "sessionId": "86b00270-889f-227b-dc3c-f980ebab0536"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:41:53.03749
730	SYSTEM	6	\N	\N	c8101672-d857-42a4-a8f3-f5b0e59c2939	\N	2026-07-13 10:41:54.498306	{"reason": "", "sessionId": "a68969a5-0cdd-ce12-ab95-0305abfb4beb"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:41:54.498306
731	SYSTEM	6	\N	\N	1a606594-0f96-4d08-a611-03c5e6ae16b2	\N	2026-07-13 10:41:54.717233	{"sessionId": "44c7f7c4-f33a-7963-384d-68c1d43ada2f"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:41:54.717233
732	USER	6	\N	\N	25cdf099-57c9-4d5a-9b50-40ffed1702c4	\N	2026-07-13 10:42:00.759617	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 10:42:00.75911
733	SYSTEM	6	\N	\N	db5fc5d1-2d59-4640-b9d1-b821fc1141a9	\N	2026-07-13 10:42:02.03393	{"reason": "", "sessionId": "44c7f7c4-f33a-7963-384d-68c1d43ada2f"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:42:02.03393
734	RIDER	6	John Rider	\N	ef5c6e82-f7bd-4d58-a1db-13c0f9ec9e81	\N	2026-07-13 10:42:04.446589	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:42:04.446589
735	SYSTEM	6	\N	\N	856d43e4-26d6-4e89-89da-4617223bcbd4	\N	2026-07-13 10:42:05.047996	{"sessionId": "323ede9d-a174-cf9b-f25b-9a2d4cc6f9b6"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:42:05.047996
736	SYSTEM	6	\N	\N	56a990c3-5255-400c-9bfa-076b12e17aa9	\N	2026-07-13 10:52:40.946529	{"reason": "", "sessionId": "323ede9d-a174-cf9b-f25b-9a2d4cc6f9b6"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 10:52:40.946529
737	RIDER	6	John Rider	\N	bc66e852-aed2-4828-9c00-374866fa044b	\N	2026-07-13 10:56:48.925277	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 10:56:48.925277
738	SYSTEM	6	\N	\N	20ee780e-b8b4-4fad-bcb0-43cddc9da68c	\N	2026-07-13 10:56:49.913965	{"sessionId": "ee20d067-4cea-f8f5-4749-58d41a6ea03d"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 10:56:49.913965
739	RIDER	6	John Rider	\N	4c21f724-1ec4-4797-bf24-7f2dedb56525	\N	2026-07-13 11:08:23.718044	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 11:08:23.718044
740	SYSTEM	6	\N	\N	3d15e8d2-e9aa-4b85-a68f-c9290c3a1b79	\N	2026-07-13 11:08:24.556529	{"sessionId": "a7772275-1b18-28a7-e254-cf8e106f15ac"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 11:08:24.556529
741	SYSTEM	6	\N	\N	9f9b294b-ea62-4313-8496-fcde8cd304a2	\N	2026-07-13 11:11:57.392776	{"reason": "", "sessionId": "a7772275-1b18-28a7-e254-cf8e106f15ac"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 11:11:57.392776
742	RIDER	6	John Rider	\N	328a1c6c-0ec2-4d85-bc15-a3a2220db7c3	\N	2026-07-13 11:15:16.146882	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 11:15:16.146882
743	SYSTEM	6	\N	\N	6e8fb2bf-a70e-4248-b263-dc97d28b3af3	\N	2026-07-13 11:15:16.782122	{"sessionId": "79c0d2a4-a03e-ce24-6dc4-a9d078caefed"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 11:15:16.782122
744	SYSTEM	6	\N	\N	7735756b-71fa-4240-baaa-10e947407786	\N	2026-07-13 11:31:31.292784	{"reason": "", "sessionId": "79c0d2a4-a03e-ce24-6dc4-a9d078caefed"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 11:31:31.292784
745	RIDER	6	John Rider	\N	53bc4ed7-c219-43d0-89d0-9cde3e976476	\N	2026-07-13 15:15:26.606359	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 15:15:26.606359
746	SYSTEM	6	\N	\N	d8eebfde-e41e-4d65-89bc-3c38f5dc1e65	\N	2026-07-13 15:15:28.043966	{"sessionId": "f43205b7-05b6-e7e5-ec40-8ea66c8ba5ad"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 15:15:28.043966
747	DRIVER	7	Mike Driver	\N	d243838e-957e-4455-b951-210825977922	\N	2026-07-13 15:27:32.326493	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 15:27:32.326493
748	SYSTEM	7	\N	\N	b28e2440-f31a-45e8-872f-dfc949901015	\N	2026-07-13 15:27:33.280239	{"sessionId": "e34cd4c5-4178-36be-39b2-55e5d44b5072"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 15:27:33.280239
749	DRIVER	7	\N	\N	61e16f11-5c2d-4e2a-b95a-b3c47e15b878	\N	2026-07-13 15:27:42.516501	{"category": "BUSINESS"}	DRIVER_WENT_ONLINE	f	\N	\N	\N	2026-07-13 15:27:42.516501
750	RIDER	6	John Rider	\N	c9fea9d5-9737-4c89-b0c5-f5746a00624b	\N	2026-07-13 15:39:40.138925	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 15:39:40.138925
751	SYSTEM	6	\N	\N	0c5f9f05-a373-44f5-a91d-eedd52d0a433	\N	2026-07-13 15:39:43.397962	{"sessionId": "a34cdda5-e07a-8aca-9743-c5b4032d8423"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 15:39:43.397962
752	DRIVER	7	Mike Driver	\N	39d41c03-4417-48ad-8052-aa251eb3c095	\N	2026-07-13 15:40:53.132276	{"email": "driver2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 15:40:53.132276
753	SYSTEM	7	\N	\N	4b8dddfe-f01a-4db2-bb4f-813a8fdddc9e	\N	2026-07-13 15:40:53.740029	{"sessionId": "b43fa063-2601-35cd-f377-2a36be777600"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 15:40:53.740029
754	DRIVER	7	\N	\N	9c40982d-7fca-44b3-8bd2-2692415f8aae	\N	2026-07-13 15:41:50.386993	{"category": "BUSINESS"}	DRIVER_WENT_OFFLINE	f	\N	\N	\N	2026-07-13 15:41:50.386993
755	DRIVER	7	\N	\N	c023ff6c-7a22-4614-9927-30642eda834f	\N	2026-07-13 15:41:59.055004	{"category": "BUSINESS"}	DRIVER_WENT_ONLINE	f	\N	\N	\N	2026-07-13 15:41:59.054497
756	USER	6	\N	\N	d486a29f-33ed-44e0-8c09-478c363c380f	\N	2026-07-13 15:42:53.766819	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 15:42:53.766819
757	SYSTEM	6	\N	\N	c35a29cf-1eed-45e7-8605-2e0b8918893c	\N	2026-07-13 15:42:54.433925	{"reason": "", "sessionId": "a34cdda5-e07a-8aca-9743-c5b4032d8423"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 15:42:54.433925
758	ADMIN	1	Mustafa	\N	a361d4ee-0ff0-4a15-a714-570288e1dee1	\N	2026-07-13 15:43:09.427309	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-13 15:43:09.427309
759	SYSTEM	1	\N	\N	92027ea7-5f94-40d0-9ef4-e86052fed876	\N	2026-07-13 15:43:10.132987	{"sessionId": "585a8b43-8c2e-daee-56e0-15d6965d80f4"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 15:43:10.132987
760	SYSTEM	7	\N	\N	f44676bf-3ed2-4131-b426-4ed8dd608cab	\N	2026-07-13 15:44:08.358963	{"reason": "", "sessionId": "b43fa063-2601-35cd-f377-2a36be777600"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 15:44:08.358963
761	SYSTEM	1	\N	\N	196aa9c8-caab-476a-b96a-9fc77f7b31ca	\N	2026-07-13 15:44:10.768093	{"reason": "", "sessionId": "585a8b43-8c2e-daee-56e0-15d6965d80f4"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 15:44:10.768093
762	SYSTEM	7	\N	\N	bc9fca3b-4ddf-4ff3-b964-c140dc579e06	\N	2026-07-13 15:54:26.99535	{"reason": "Inactive for 10 minutes", "category": "SCHEDULER"}	DRIVER_AUTO_OFFLINE	f	\N	\N	\N	2026-07-13 15:54:26.99535
763	RIDER	6	John Rider	\N	f8426183-c97a-48b4-a0a3-f2606a478ef2	\N	2026-07-13 16:01:11.498649	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 16:01:11.498649
764	RIDER	6	John Rider	\N	2ba5fc13-624e-4fcf-a3d9-dcabdafe51d6	\N	2026-07-13 16:02:34.135743	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 16:02:34.135743
765	RIDER	6	John Rider	\N	a970ffad-eff3-4b45-8b9d-0b26d6011b16	\N	2026-07-13 16:05:29.644167	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 16:05:29.644167
766	ADMIN	1	Mustafa	\N	d236cea0-0d4b-4c0e-bf0d-cf74dcf16379	\N	2026-07-13 16:08:34.269649	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-13 16:08:34.269649
767	USER	1	\N	\N	ff1eca96-e33c-47ab-bfa4-30ace4655c9a	\N	2026-07-13 16:08:34.906731	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-13 16:08:34.906731
768	SYSTEM	1	\N	\N	984750f0-c2e6-42b1-a7d9-7e72ed68e40f	\N	2026-07-13 16:08:35.700263	{"sessionId": "b80a23cc-b9a5-2e46-14c5-11884da458e9"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 16:08:35.700263
769	SYSTEM	1	\N	\N	159d518c-5083-47d6-abad-fcb4c66ab35c	\N	2026-07-13 16:09:55.627417	{"reason": "", "sessionId": "b80a23cc-b9a5-2e46-14c5-11884da458e9"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 16:09:55.627417
770	RIDER	6	John Rider	\N	3209b067-eb8c-4d8e-aefb-8e3e4fd8a917	\N	2026-07-13 16:17:41.427779	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 16:17:41.427779
771	USER	6	\N	\N	31e68d22-1aa7-475f-a4c3-7c84e9e88eb9	\N	2026-07-13 16:17:42.021673	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-13 16:17:42.021673
772	SYSTEM	6	\N	\N	a511986e-c516-4b08-b492-fd006b4c8402	\N	2026-07-13 16:17:42.827971	{"sessionId": "19c48905-6fb1-64a9-2f97-e3a8ed0aa9ba"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 16:17:42.827971
773	SYSTEM	6	\N	\N	26afbdc4-aac0-4cfc-8066-bcc24cc27500	\N	2026-07-13 16:19:19.788742	{"reason": "", "sessionId": "19c48905-6fb1-64a9-2f97-e3a8ed0aa9ba"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 16:19:19.78774
774	USER	6	\N	\N	ccb00bfd-ed95-4175-b814-821f6783a677	\N	2026-07-13 16:29:23.702217	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 16:29:23.701219
775	ADMIN	1	Mustafa	\N	3f5d5147-9770-4401-a251-c001eea16522	\N	2026-07-13 16:29:40.145996	{"email": "muasi@yahoo.com"}	LOGIN	f	\N	\N	\N	2026-07-13 16:29:40.145996
776	USER	1	\N	\N	0927a5cc-e94e-4930-8218-024cb9aa1af8	\N	2026-07-13 16:29:40.751231	{"category": "BUSINESS"}	DEVICE_TOKEN_UPDATED	f	\N	\N	\N	2026-07-13 16:29:40.751231
777	SYSTEM	1	\N	\N	b2f8b913-7600-485e-8629-04074ca8741a	\N	2026-07-13 16:29:41.559139	{"sessionId": "4d6db482-ee83-ab1f-e9c5-ddccc73139d1"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 16:29:41.559139
778	SYSTEM	1	\N	\N	6e76ad1c-be34-4a67-a39d-c435897b8f40	\N	2026-07-13 16:30:37.88058	{"reason": "", "sessionId": "4d6db482-ee83-ab1f-e9c5-ddccc73139d1"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 16:30:37.88058
779	RIDER	6	John Rider	\N	4559be4a-e392-402b-b922-c972a86ae204	\N	2026-07-13 16:48:14.290912	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 16:48:14.290912
780	SYSTEM	6	\N	\N	d3c93400-4ec7-43ca-8e6d-096290a27d95	\N	2026-07-13 16:48:15.30625	{"sessionId": "ef780506-be64-6308-61af-f1afed51388e"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 16:48:15.30625
781	SYSTEM	6	\N	\N	2810641d-d7d6-4401-90b7-51dfc8734585	\N	2026-07-13 16:58:07.178441	{"sessionId": "f0de2383-ba8d-1ddc-0767-1e0dcd2cb15b"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 16:58:07.177443
782	SYSTEM	6	\N	\N	b5e8a322-6e01-4dcb-a06a-4f4c3b7ba5b4	\N	2026-07-13 16:58:10.712849	{"reason": "", "sessionId": "ef780506-be64-6308-61af-f1afed51388e"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 16:58:10.712849
783	SYSTEM	6	\N	\N	f0071ea6-3028-4430-8020-666193effe62	\N	2026-07-13 16:58:14.785266	{"reason": "", "sessionId": "f0de2383-ba8d-1ddc-0767-1e0dcd2cb15b"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 16:58:14.785266
784	SYSTEM	6	\N	\N	9cbfccc5-3dab-461e-aa78-e9f516c5abfe	\N	2026-07-13 16:58:15.371268	{"sessionId": "fe5836a1-9a15-10fb-255c-ae37e2e4a6ec"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 16:58:15.371268
785	USER	6	\N	\N	1deacc0c-1116-4c37-b36a-8f284df0adff	\N	2026-07-13 16:58:23.577356	{"category": "BUSINESS"}	LOGOUT	f	\N	\N	\N	2026-07-13 16:58:23.577356
786	SYSTEM	6	\N	\N	16aee350-7fac-49e3-bf75-09f88d77789c	\N	2026-07-13 16:58:24.917475	{"reason": "", "sessionId": "fe5836a1-9a15-10fb-255c-ae37e2e4a6ec"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 16:58:24.917475
787	RIDER	6	John Rider	\N	382e0e19-880a-4ad3-92da-cc7e39822b62	\N	2026-07-13 16:58:27.512784	{"email": "rider2@test.com"}	LOGIN	f	\N	\N	\N	2026-07-13 16:58:27.512784
788	SYSTEM	6	\N	\N	041617f4-0a1d-46c0-b91a-10648b5fb5b4	\N	2026-07-13 16:58:28.388714	{"sessionId": "78eef241-fe4e-2846-b3c3-037630302402"}	WEBSOCKET_CONNECTED	f	\N	\N	\N	2026-07-13 16:58:28.388714
789	SYSTEM	6	\N	\N	2cc21baf-c8c0-4fdd-9115-666c792db361	\N	2026-07-13 16:59:37.993442	{"reason": "", "sessionId": "78eef241-fe4e-2846-b3c3-037630302402"}	WEBSOCKET_DISCONNECTED	f	\N	\N	\N	2026-07-13 16:59:37.992441
\.


--
-- Data for Name: ride_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ride_events (id, details, event_type, ride_id, "timestamp", user_id) FROM stdin;
\.


--
-- Data for Name: rides; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rides (id, rider_id, driver_id, pickup_latitude, pickup_longitude, pickup_address, dropoff_latitude, dropoff_longitude, dropoff_address, status, ride_type, estimated_fare, final_fare, estimated_distance, estimated_duration, requested_at, accepted_at, started_at, completed_at, cancelled_at, cancellation_reason, arrived_at_pickup_at, driver_current_latitude, driver_current_longitude, driver_location_updated_at, driver_arrived_at, last_timeout_notification, search_radius_km, selected_ride_type, version, cancelled_by, payment_method, scheduled_ride_id) FROM stdin;
145	6	7	26.377726622733437	50.12094282274372	KSA-DAM-حي الفردوس-2ا	26.36504257354514	50.10321878557331	Dropoff location	CANCELLED	ECONOMY	2.88	\N	4.423	8	2026-06-28 14:13:10.69732	2026-06-28 14:13:24.980402	2026-06-28 14:15:37.23285	\N	2026-06-28 14:16:13.231479		\N	\N	\N	\N	2026-06-28 14:15:09.398502	\N	15	ECONOMY	4	\N	\N	\N
160	6	7	26.397854669814333	50.14570651575923	KSA-DAM-King Fahd Road	26.37857123521914	50.12140704318881	KSA-الد-حي الفردوس-1ب	CANCELLED	ECONOMY	3.44	\N	7.187	10	2026-06-30 09:59:08.347075	2026-06-30 09:59:30.086031	2026-06-30 10:01:24.280135	\N	2026-06-30 10:01:48.552419		\N	\N	\N	\N	2026-06-30 10:00:29.123247	\N	15	ECONOMY	4	\N	\N	\N
139	6	7	26.397925482046716	50.14562553912591		26.396041847074578	50.14465994388055	Dropoff location	COMPLETED	ECONOMY	2.06	2.06	0.298	1	2026-06-22 17:05:53.273475	2026-06-22 17:06:03.293755	2026-06-22 17:06:16.925817	2026-06-22 17:06:22.582344	\N	\N	\N	\N	\N	\N	2026-06-22 17:06:09.023801	\N	15	ECONOMY	4	\N	\N	\N
151	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	CANCELLED	ECONOMY	2.57	\N	2.864	4	2026-06-29 14:40:26.872445	2026-06-29 14:40:40.643369	\N	\N	2026-06-29 14:45:20.983599	driver did not come	\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
146	6	7	26.377726622733437	50.12094282274372	KSA-DAM-حي الفردوس-2ا	26.36504257354514	50.10321878557331	Dropoff location	CANCELLED	ECONOMY	2.88	\N	4.423	8	2026-06-28 14:16:42.448184	2026-06-28 14:16:56.064389	2026-06-28 14:20:36.664237	\N	2026-06-28 14:22:50.541499		\N	\N	\N	\N	2026-06-28 14:18:35.194456	\N	15	ECONOMY	4	\N	\N	\N
140	6	7	26.377685118093886	50.121760809251455		26.352171518078187	50.15537614422616	Dropoff location	COMPLETED	ECONOMY	3.55	3.55	7.748	9	2026-06-22 21:43:05.47366	2026-06-22 21:43:15.893817	2026-06-22 21:45:32.153047	2026-06-22 21:46:08.8425	\N	\N	\N	\N	\N	\N	2026-06-22 21:44:30.672055	\N	15	ECONOMY	4	\N	\N	\N
156	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	COMPLETED	ECONOMY	2.57	2.57	2.864	4	2026-06-29 14:59:55.031215	2026-06-29 15:00:05.791165	2026-06-29 15:00:44.090328	2026-06-29 15:00:58.081979	\N	\N	\N	\N	\N	\N	2026-06-29 15:00:24.687905	\N	15	ECONOMY	4	\N	\N	\N
147	6	7	26.37853084695673	50.1207703538239	KSA-DAM-حي الفردوس-2ا	26.370870043060876	50.1190591044724	KSA-DHA-حي هجر-6	CANCELLED	ECONOMY	2.50	\N	2.486	7	2026-06-28 23:10:17.418991	2026-06-28 23:10:27.207867	\N	\N	2026-06-28 23:11:05.676238		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
141	6	7	26.376779444272408	50.121232431430315		26.372302378945886	50.10479759866202	Dropoff location	COMPLETED	ECONOMY	2.58	2.58	2.909	5	2026-06-22 21:52:03.342184	2026-06-22 21:52:14.822116	2026-06-22 21:53:35.828295	2026-06-22 21:53:48.189568	\N	\N	\N	\N	\N	\N	2026-06-22 21:53:16.923944	\N	15	ECONOMY	4	\N	\N	\N
152	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	CANCELLED	ECONOMY	2.57	\N	2.864	4	2026-06-29 14:49:29.04653	2026-06-29 14:49:42.063784	\N	\N	2026-06-29 14:50:26.560073		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
142	6	7	26.378540072377923	50.12229351427802	26.3785, 50.1223	26.36764783835453	50.10530826146378	Dropoff location	COMPLETED	ECONOMY	2.82	2.82	4.094	6	2026-06-22 22:06:54.239529	2026-06-22 22:07:01.493796	2026-06-22 22:07:13.802797	2026-06-22 22:07:22.393241	\N	\N	\N	\N	\N	\N	2026-06-22 22:07:09.715056	\N	15	ECONOMY	4	\N	\N	\N
148	6	7	26.378528744390458	50.12155054137111	KSA-الد-حي الفردوس-1ب	26.375369745544113	50.11912951245904	KSA-DAM-حي الفردوس-الخلافة	COMPLETED	ECONOMY	2.13	2.13	0.658	3	2026-06-28 23:11:44.613847	2026-06-28 23:11:53.20251	2026-06-28 23:14:55.138633	2026-06-28 23:17:25.70113	\N	\N	\N	\N	\N	\N	2026-06-28 23:13:59.182705	\N	15	ECONOMY	4	\N	\N	\N
143	6	7	26.377726622733437	50.12094282274372	KSA-DAM-حي الفردوس-2ا	26.36504257354514	50.10321878557331	Dropoff location	COMPLETED	ECONOMY	2.88	2.88	4.423	8	2026-06-22 22:16:53.530498	2026-06-22 22:17:04.581825	2026-06-22 22:17:12.814401	2026-06-22 22:17:16.869254	\N	\N	\N	\N	\N	\N	2026-06-22 22:17:09.784728	\N	15	ECONOMY	4	\N	\N	\N
153	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	CANCELLED	ECONOMY	2.57	\N	2.864	4	2026-06-29 14:51:36.240671	2026-06-29 14:51:50.404243	\N	\N	2026-06-29 14:52:13.355833		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
149	6	\N	24.638545908173754	46.57088109163782	KSA-RIY-حي ظهرة لبن-قرطاجنة	24.69675430159665	46.79462155341833	KSA-RIY-حي الروابي-Al Zoubair Ibn Al Awwam	CANCELLED	ECONOMY	8.67	\N	33.359	38	2026-06-29 14:17:55.92006	\N	\N	\N	2026-06-29 14:19:13.868774	Rider cancelled search	\N	\N	\N	\N	\N	2026-06-29 14:18:56.918392	15	ECONOMY	2	\N	\N	\N
144	6	7	26.377726622733437	50.12094282274372	KSA-DAM-حي الفردوس-2ا	26.36504257354514	50.10321878557331	Dropoff location	COMPLETED	LUXURY	8.21	8.21	4.423	8	2026-06-28 10:42:42.836508	2026-06-28 10:43:26.848824	2026-06-28 10:45:24.379641	2026-06-28 10:45:55.097083	\N	\N	\N	\N	\N	\N	2026-06-28 10:44:49.280851	\N	15	LUXURY	4	\N	\N	\N
154	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	CANCELLED	ECONOMY	2.57	\N	2.864	4	2026-06-29 14:58:22.368918	2026-06-29 14:58:30.868622	\N	\N	2026-06-29 14:58:38.00703		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
150	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	CANCELLED	ECONOMY	2.57	\N	2.864	4	2026-06-29 14:19:56.283181	2026-06-29 14:20:15.685005	2026-06-29 14:23:50.20931	\N	2026-06-29 14:24:55.227995		\N	\N	\N	\N	2026-06-29 14:21:25.700358	\N	15	ECONOMY	4	\N	\N	\N
162	6	7	26.397854669814333	50.14570651575923	KSA-DAM-King Fahd Road	26.37857123521914	50.12140704318881	KSA-الد-حي الفردوس-1ب	CANCELLED	ECONOMY	3.44	\N	7.187	10	2026-06-30 11:29:29.35754	2026-06-30 11:30:05.751747	\N	\N	2026-06-30 11:32:20.368456		\N	\N	\N	\N	2026-06-30 11:31:33.925518	\N	15	ECONOMY	3	\N	\N	\N
155	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	CANCELLED	ECONOMY	2.57	\N	2.864	4	2026-06-29 14:59:14.80071	2026-06-29 14:59:25.336337	\N	\N	2026-06-29 14:59:41.677113		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
159	6	7	26.397854669814333	50.14570651575923	KSA-DAM-King Fahd Road	26.37857123521914	50.12140704318881	KSA-الد-حي الفردوس-1ب	COMPLETED	LUXURY	9.59	9.59	7.187	10	2026-06-30 09:51:43.284772	2026-06-30 09:51:57.167512	2026-06-30 09:54:31.139861	2026-06-30 09:55:32.363125	\N	\N	\N	\N	\N	\N	2026-06-30 09:54:09.819963	\N	15	LUXURY	4	\N	\N	\N
157	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	COMPLETED	ECONOMY	2.57	2.57	2.864	4	2026-06-29 15:12:39.432357	2026-06-29 15:12:49.374307	2026-06-29 15:14:46.285068	2026-06-29 15:15:27.799744	\N	\N	\N	\N	\N	\N	2026-06-29 15:14:29.42974	\N	15	ECONOMY	4	\N	\N	\N
161	6	7	26.397854669814333	50.14570651575923	KSA-DAM-King Fahd Road	26.37857123521914	50.12140704318881	KSA-الد-حي الفردوس-1ب	CANCELLED	ECONOMY	3.44	\N	7.187	10	2026-06-30 10:02:33.211521	2026-06-30 10:02:46.703062	\N	\N	2026-06-30 11:25:27.219708	Cancelled by rider (stale ride cleanup)	\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
158	6	7	26.3938704185018	50.14723469746672	KSA-DAM-7 Street	26.37731420729086	50.14338297559995	KSA-DAM-Al Nahdah-ابو علي الرشيد	CANCELLED	ECONOMY	2.57	\N	2.864	4	2026-06-30 00:09:16.825564	2026-06-30 00:09:27.833153	\N	\N	2026-06-30 00:11:19.688538	driver not came	\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
163	6	7	26.397854669814333	50.14570651575923	KSA-DAM-King Fahd Road	26.37857123521914	50.12140704318881	KSA-الد-حي الفردوس-1ب	CANCELLED	ECONOMY	3.44	\N	7.187	10	2026-06-30 11:32:51.893515	2026-06-30 11:33:03.462621	\N	\N	2026-06-30 11:33:40.666861		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
164	6	7	26.39786392190101	50.14568941667676	KSA-DAM-King Fahd Road	26.394065458509566	50.14474527910352	KSA-DAM	CANCELLED	ECONOMY	2.12	\N	0.598	1	2026-06-30 11:39:55.26315	2026-06-30 11:40:06.152982	\N	\N	2026-06-30 11:44:20.55316		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
165	6	7	26.39786392190101	50.14568941667676	KSA-DAM-King Fahd Road	26.394065458509566	50.14474527910352	KSA-DAM	CANCELLED	ECONOMY	2.12	\N	0.598	1	2026-06-30 16:00:51.583942	2026-06-30 16:01:19.278094	\N	\N	2026-06-30 16:02:04.779003		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
166	6	7	26.39786392190101	50.14568941667676	KSA-DAM-King Fahd Road	26.394065458509566	50.14474527910352	KSA-DAM	CANCELLED	ECONOMY	2.12	\N	0.598	1	2026-06-30 16:04:22.839925	2026-06-30 16:04:37.112214	\N	\N	2026-06-30 16:05:33.044625		\N	\N	\N	\N	2026-06-30 16:04:57.253872	\N	15	ECONOMY	3	\N	\N	\N
167	6	7	26.39786392190101	50.14568941667676	KSA-DAM-King Fahd Road	26.394065458509566	50.14474527910352	KSA-DAM	CANCELLED	ECONOMY	2.12	\N	0.598	1	2026-06-30 16:12:05.184133	2026-06-30 16:12:10.980518	\N	\N	2026-06-30 16:18:36.637911		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
168	6	7	26.39786392190101	50.14568941667676	KSA-DAM-King Fahd Road	26.394065458509566	50.14474527910352	KSA-DAM	CANCELLED	ECONOMY	2.12	\N	0.598	1	2026-06-30 16:30:15.717529	2026-06-30 16:30:22.13545	\N	\N	2026-06-30 16:36:36.417571		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
169	6	7	26.378561019927403	50.12136211618781	KSA-الد-حي الفردوس-1ب	26.3775757769916	50.1169746927917	KSA-DAM-Al Firdaws-7 Street	COMPLETED	ECONOMY	2.15	2.15	0.756	3	2026-06-30 21:02:33.743604	2026-06-30 21:02:41.293619	2026-06-30 21:08:00.215621	2026-06-30 21:10:55.656224	\N	\N	\N	\N	\N	\N	2026-06-30 21:04:49.386752	\N	15	ECONOMY	4	\N	\N	\N
175	6	7	26.378597233279372	50.12138407677412	KSA-الد-حي الفردوس-1ب	26.399882350352453	50.116868913173676	KSA-DAM-Al Shifa-Prince Mohammed Bin	COMPLETED	ECONOMY	2.87	2.87	4.348	6	2026-07-02 21:29:25.948637	2026-07-02 21:29:38.933567	2026-07-02 21:42:42.247644	2026-07-02 21:48:09.194174	\N	\N	\N	\N	\N	\N	2026-07-02 21:31:59.894839	\N	15	ECONOMY	4	\N	\N	\N
180	6	7	26.349696804481013	50.14978934079409		26.358441125246397	50.14740653336048	KSA-الظ-حي القصور-3أ	CANCELLED	ECONOMY	2.24	\N	1.219	3	2026-07-03 19:05:49.345569	2026-07-03 19:05:58.898427	2026-07-03 19:11:29.446142	\N	2026-07-03 19:11:45.173533		\N	\N	\N	\N	2026-07-03 19:10:43.281967	\N	15	ECONOMY	4	\N	\N	\N
170	6	7	26.378176184448026	50.11661292985082	KSA-DAM-Hajar-Salsabil Street	26.38008162933842	50.12076096609235	KSA-الد-حي الفردوس-الاقتصاد	COMPLETED	ECONOMY	2.11	2.11	0.569	2	2026-06-30 21:13:30.616224	2026-06-30 21:13:47.70117	2026-06-30 21:14:59.980712	2026-06-30 21:16:30.019041	\N	\N	\N	\N	\N	\N	2026-06-30 21:14:51.364011	\N	15	ECONOMY	4	\N	\N	\N
176	6	7	26.40025637430594	50.1166657358408	KSA-DAM-Al Shifa-Prince Mohammed Bin	26.378671078517336	50.12136496603489	KSA-DAM-Hajar-Balaghah Street	CANCELLED	ECONOMY	3.78	\N	8.898	12	2026-07-03 00:15:53.613184	2026-07-03 00:16:14.153502	\N	\N	2026-07-03 00:28:38.74954		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
171	6	7	26.378176184448026	50.11661292985082	KSA-DAM-Hajar-Salsabil Street	26.38008162933842	50.12076096609235	KSA-الد-حي الفردوس-الاقتصاد	COMPLETED	ECONOMY	2.11	2.11	0.569	2	2026-07-01 16:30:46.548878	2026-07-01 16:31:12.499777	2026-07-01 16:33:47.444448	2026-07-01 16:36:10.202746	\N	\N	\N	\N	\N	\N	2026-07-01 16:33:41.494204	\N	15	ECONOMY	4	\N	\N	\N
186	1	7	26.37860008655994	50.12139866128564	KSA-الد-حي الفردوس-1ب	26.376025461925934	50.12007834389806	KSA-DAM-حي الفردوس-3	COMPLETED	ECONOMY	2.13	2.13	0.652	3	2026-07-05 22:56:01.289191	2026-07-05 22:56:07.386657	2026-07-05 22:57:03.823259	2026-07-05 22:57:19.866681	\N	\N	\N	\N	\N	\N	2026-07-05 22:56:51.726288	\N	15	ECONOMY	4	\N	\N	\N
177	6	7	26.412912294636	50.111590661108494	KSA-DAM-حي الشفاء-الامام علي بن ابي طالب	26.378600232759812	50.12137033045292	KSA-الد-حي الفردوس-1ب	CANCELLED	ECONOMY	3.29	\N	6.46	10	2026-07-03 00:32:15.991017	2026-07-03 00:32:30.886696	2026-07-03 00:33:02.623001	\N	2026-07-03 00:44:08.169256		\N	\N	\N	\N	2026-07-03 00:32:38.367843	\N	15	ECONOMY	4	\N	\N	\N
172	6	7	26.378176184448026	50.11661292985082	KSA-DAM-Hajar-Salsabil Street	26.38008162933842	50.12076096609235	KSA-الد-حي الفردوس-الاقتصاد	COMPLETED	ECONOMY	2.11	2.11	0.569	2	2026-07-01 19:28:31.621097	2026-07-01 19:28:40.573812	2026-07-01 19:33:01.823268	2026-07-01 19:33:22.426506	\N	\N	\N	\N	\N	\N	2026-07-01 19:32:33.711338	\N	15	ECONOMY	4	\N	\N	\N
173	6	7	26.378630261969008	50.12135021388531	KSA-DAM-Hajar-Balaghah Street	26.37945852849768	50.118789710104465	KSA-DAM-حي الفردوس-4	CANCELLED	ECONOMY	2.08	\N	0.419	2	2026-07-01 21:57:01.507195	2026-07-01 21:57:15.89125	\N	\N	2026-07-01 22:01:26.415958		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
184	6	7	26.378621254686614	50.121381394565105	KSA-DAM-Al Firdaws-1 ب	26.377187610738325	50.12160938233137	KSA-DAM-Al Firdaws-Al Balaghah	COMPLETED	ECONOMY	2.04	2.04	0.195	2	2026-07-05 21:50:12.789378	2026-07-05 21:50:26.385414	2026-07-05 21:54:39.743851	2026-07-05 21:56:53.232531	\N	\N	\N	\N	\N	\N	2026-07-05 21:52:53.897105	\N	15	ECONOMY	4	\N	\N	\N
178	6	7	26.378601135527152	50.12137971818447	KSA-DAM-حي الفردوس-1ب	26.378076620395003	50.1190847530961	KSA-DAM-Hajar-Balaghah Street	CANCELLED	ECONOMY	2.12	\N	0.579	3	2026-07-03 18:11:36.042823	2026-07-03 18:11:56.671657	\N	\N	2026-07-03 18:14:25.692776	User logged out	\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
174	6	7	26.378616093418028	50.121455155313015	KSA-الد-حي الفردوس-1ب	26.377299279677402	50.11848125606775	KSA-الد-حي الفردوس-السلسبيل	COMPLETED	ECONOMY	2.12	2.12	0.601	3	2026-07-02 20:42:14.646911	2026-07-02 20:42:34.185002	2026-07-02 20:50:07.440966	2026-07-02 20:52:00.158996	\N	\N	\N	\N	\N	\N	2026-07-02 20:44:12.147336	\N	15	ECONOMY	4	\N	\N	\N
181	6	7	26.378662049465937	50.121348202228546	KSA-DAM-Al Muntazah-619	26.378300407915027	50.119112245738506	KSA-DAM-حي الفردوس-4	CANCELLED	ECONOMY	2.11	\N	0.548	2	2026-07-03 19:35:06.037409	2026-07-03 19:35:11.299987	2026-07-03 19:39:08.905438	\N	2026-07-03 19:43:28.711133	لم يعمل	\N	\N	\N	\N	2026-07-03 19:36:22.336345	\N	15	ECONOMY	4	\N	\N	\N
187	1	\N	26.37575452505392	50.121407713741064	KSA-الد-حي الفردوس-1ب	21.429901103261557	39.81586078181863	KSA-MAK-At Taysir-Beir Tawa	CANCELLED	ECONOMY	258.67	\N	1283.326	781	2026-07-05 22:58:59.238696	\N	\N	\N	2026-07-05 22:59:44.301277	Rider cancelled search	\N	\N	\N	\N	\N	\N	15	ECONOMY	1	\N	\N	\N
179	6	7	26.3786146524861	50.12138910591602	KSA-الد-حي الفردوس-1ب	26.349655992079505	50.141645818948746	KSA-DHA-Aljamiah District-619	COMPLETED	ECONOMY	3.34	3.34	6.706	9	2026-07-03 18:17:39.417278	2026-07-03 18:17:56.72906	2026-07-03 18:18:22.321974	2026-07-03 18:27:39.117169	\N	\N	\N	\N	\N	\N	2026-07-03 18:18:04.567073	\N	15	ECONOMY	4	\N	\N	\N
182	6	7	26.37904144531015	50.11889196932316	KSA-DAM-حي الفردوس-4	26.378617356558717	50.121387094259255	KSA-الد-حي الفردوس-1ب	CANCELLED	ECONOMY	2.09	\N	0.468	3	2026-07-03 19:45:17.33522	2026-07-03 19:45:23.510488	\N	\N	2026-07-03 19:47:08.717781		\N	\N	\N	\N	2026-07-03 19:47:00.557172	\N	15	ECONOMY	3	\N	\N	\N
190	6	14	26.374430172506262	50.12257531285286	KSA-DAM-Hajar-Prince Mohammed Bin	26.378648850222262	50.12132104486227	KSA-الد-حي الفردوس-1ب	CANCELLED	ECONOMY	2.13	\N	0.647	2	2026-07-06 20:52:10.163394	2026-07-06 20:52:13.049385	\N	\N	2026-07-06 20:53:33.552334		\N	\N	\N	\N	2026-07-06 20:52:18.225655	\N	15	ECONOMY	3	\N	\N	\N
185	1	7	26.37851177178503	50.12139430269599	KSA-الد-حي الفردوس-1ب	26.375965387286286	50.11635074391961	KSA-DAM-Hajar-7 Street	CANCELLED	ECONOMY	2.19	\N	0.939	4	2026-07-05 22:53:13.523453	2026-07-05 22:53:35.453524	2026-07-05 22:55:01.460842	\N	2026-07-05 22:55:41.68513		\N	\N	\N	\N	2026-07-05 22:53:48.230817	\N	15	ECONOMY	4	\N	\N	\N
183	6	7	26.378613733665432	50.121385753154755	KSA-DAM-Al Firdaws-Prince Mohammed Bin	26.400267493369725	50.11676732450724	KSA-DAM-Al Shifa-Prince Mohammed Bin	COMPLETED	ECONOMY	2.88	2.88	4.394	7	2026-07-03 21:18:51.702401	2026-07-03 21:19:03.288265	2026-07-03 21:22:29.534375	2026-07-03 21:26:51.471229	\N	\N	\N	\N	\N	\N	2026-07-03 21:19:43.200954	\N	15	ECONOMY	4	\N	\N	\N
189	6	14	26.335489554252558	50.11983543634415	KSA-DHA-Gharb Al Dhahran-Ring Road	26.378609548434934	50.12136731296778	KSA-الد-حي الفردوس-1ب	CANCELLED	ECONOMY	4.01	\N	10.052	14	2026-07-06 20:25:01.768189	2026-07-06 20:25:20.03776	2026-07-06 20:41:07.98278	\N	2026-07-06 20:41:54.294657	User logged out	\N	\N	\N	\N	2026-07-06 20:38:52.775861	\N	15	ECONOMY	4	\N	\N	\N
188	1	7	26.378483102235972	50.121311992406845	KSA-الد-حي الفردوس-1ب	26.378033438785323	50.11700788512826	KSA-DAM-Al Firdaws-7 Street	COMPLETED	ECONOMY	2.17	2.17	0.832	3	2026-07-05 22:59:57.654951	2026-07-05 23:00:06.025059	2026-07-05 23:00:55.458304	2026-07-05 23:01:01.731302	\N	\N	\N	\N	\N	\N	2026-07-05 23:00:37.957664	\N	15	ECONOMY	4	\N	\N	\N
192	11	14	26.378639593197622	50.1213850826025	KSA-الد-حي الفردوس-1ب	26.382325859085775	50.12329816818237	KSA-DAM-حي المنتزه-10	CANCELLED	ECONOMY	2.41	\N	2.041	4	2026-07-06 21:43:11.61901	2026-07-06 21:43:15.403496	\N	\N	2026-07-06 21:46:16.777721		\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
191	6	14	26.37554420555046	50.122374817728996	KSA-DAM-Hajar-619	26.37867800392327	50.12127511203289	KSA-DAM-Hajar-Balaghah Street	CANCELLED	ECONOMY	2.11	\N	0.526	2	2026-07-06 20:53:57.565086	2026-07-06 20:53:59.341842	\N	\N	2026-07-06 21:39:41.532212	User logged out	\N	\N	\N	\N	2026-07-06 20:55:00.9829	\N	15	ECONOMY	3	\N	\N	\N
193	11	14	26.378589730103318	50.121363289654255	KSA-DAM-حي الفردوس-1ب	26.38190986425134	50.12439150363207	KSA-DAM-حي المنتزه-المسك	CANCELLED	ECONOMY	2.39	\N	1.927	5	2026-07-06 21:46:27.528201	2026-07-06 21:46:30.11132	\N	\N	2026-07-06 21:46:48.279866	Cancelled by rider (stale ride cleanup)	\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	\N	\N
194	11	14	26.378589730103318	50.121363289654255	KSA-DAM-حي الفردوس-1ب	26.38190986425134	50.12439150363207	KSA-DAM-حي المنتزه-المسك	CANCELLED	ECONOMY	2.39	\N	1.927	5	2026-07-06 21:47:14.560244	2026-07-06 21:47:17.175005	\N	\N	2026-07-06 21:47:58.679583		\N	\N	\N	\N	2026-07-06 21:47:21.738551	\N	15	ECONOMY	3	\N	\N	\N
195	6	14	26.37850962072067	50.1212970726192	KSA-الد-حي الفردوس-1ب	26.3823224122195	50.12988919392228	KSA-DAM-Al Muntazah-العناب	CANCELLED	ECONOMY	2.59	\N	2.925	6	2026-07-06 21:49:00.648222	2026-07-06 21:49:04.242802	\N	\N	2026-07-06 21:50:15.590674		\N	\N	\N	\N	2026-07-06 21:49:54.608847	\N	15	ECONOMY	3	\N	\N	\N
196	6	\N	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	CANCELLED	LUXURY	8.35	\N	4.692	8	2026-07-07 00:06:44.069747	\N	\N	\N	2026-07-07 00:06:52.253455	Rider cancelled search	\N	\N	\N	\N	\N	\N	15	LUXURY	1	\N	\N	\N
217	11	13	26.38775984897066	50.07526583969593	26.3878, 50.0754	26.400626649398653	50.115235447883606	26.4006, 50.1152	COMPLETED	LUXURY	11.55	11.55	11.098	17	2026-07-10 19:11:38.639468	2026-07-10 19:11:46.566513	2026-07-10 19:12:00.874066	2026-07-10 19:24:53.095077	\N	\N	\N	\N	\N	\N	2026-07-10 19:11:55.278339	\N	15	LUXURY	4	\N	CASH	\N
197	6	7	26.37956270144121	50.12023122981191	KSA-الد-حي الفردوس-1ب	26.37838076335042	50.118616204708815	KSA-DAM-Al Firdaws-Salsabil Street	COMPLETED	LUXURY	6.17	6.17	0.342	3	2026-07-07 00:07:09.208967	2026-07-07 00:07:15.648526	2026-07-07 00:09:03.434089	2026-07-07 00:09:11.524487	\N	\N	\N	\N	\N	\N	2026-07-07 00:07:48.835935	\N	15	LUXURY	4	\N	\N	\N
203	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	CANCELLED	ECONOMY	2.94	\N	4.692	8	2026-07-08 23:35:46.377914	2026-07-08 23:35:53.666009	\N	\N	2026-07-08 23:55:29.314388	Cancelled by rider (stale ride cleanup)	\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	WALLET	\N
211	6	13	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-09 16:00:17.594078	2026-07-09 16:00:22.060796	2026-07-09 16:00:34.898033	2026-07-09 16:00:40.505924	\N	\N	\N	\N	\N	\N	2026-07-09 16:00:28.358382	\N	15	ECONOMY	4	\N	CASH	\N
198	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-07 09:58:45.167635	2026-07-07 09:58:55.674183	2026-07-07 10:00:29.722783	2026-07-07 10:01:42.544126	\N	\N	\N	\N	\N	\N	2026-07-07 09:59:44.563176	\N	15	ECONOMY	4	\N	\N	\N
208	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-09 15:51:17.448438	2026-07-09 15:51:31.42649	2026-07-09 15:51:45.344754	2026-07-09 15:51:55.225329	\N	\N	\N	\N	\N	\N	2026-07-09 15:51:35.85679	\N	15	ECONOMY	4	\N	CASH	\N
204	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-08 23:56:09.718782	2026-07-08 23:56:21.915512	2026-07-08 23:56:34.587344	2026-07-08 23:56:40.965158	\N	\N	\N	\N	\N	\N	2026-07-08 23:56:27.913797	\N	15	ECONOMY	4	\N	CASH	\N
199	11	13	26.378685241657173	50.12136027216911	26.3787, 50.1214	26.376252786521736	50.11933587491512	26.3763, 50.1193	COMPLETED	ECONOMY	2.07	2.07	0.3373825712745526	1	2026-07-08 18:35:45.75482	2026-07-08 18:35:53.281455	2026-07-08 18:36:17.118133	2026-07-08 18:36:40.727513	\N	\N	\N	\N	\N	\N	2026-07-08 18:36:06.708062	\N	15	ECONOMY	4	\N	\N	\N
205	6	\N	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	CANCELLED	ECONOMY	2.94	\N	4.692	8	2026-07-08 23:58:05.166671	\N	\N	\N	2026-07-08 23:59:49.25417	Rider cancelled search	\N	\N	\N	\N	\N	\N	15	ECONOMY	1	\N	WALLET	\N
200	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.63	2.63	3.135810457950175	6	2026-07-08 20:36:54.808988	2026-07-08 20:37:05.621199	2026-07-08 20:37:28.23321	2026-07-08 20:37:34.779113	\N	\N	\N	\N	\N	\N	2026-07-08 20:37:18.96575	\N	15	ECONOMY	4	\N	\N	\N
218	12	\N	26.378539657383058	50.12141743674874	26.3785, 50.1213	26.377004173197932	50.11884922161698	26.3770, 50.1188	CANCELLED	ECONOMY	2.20	\N	1.003	4	2026-07-10 20:21:00.240462	\N	\N	\N	2026-07-10 20:21:47.949323	Rider cancelled search	\N	\N	\N	\N	\N	\N	15	ECONOMY	1	\N	CASH	\N
201	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-08 23:08:14.502967	2026-07-08 23:08:21.936597	2026-07-08 23:08:53.927295	2026-07-08 23:09:05.624644	\N	\N	\N	\N	\N	\N	2026-07-08 23:08:41.536688	\N	15	ECONOMY	4	\N	\N	\N
206	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-09 00:03:28.264615	2026-07-09 00:03:42.096145	2026-07-09 00:03:54.874601	2026-07-09 00:04:02.04874	\N	\N	\N	\N	\N	\N	2026-07-09 00:03:47.499369	\N	15	ECONOMY	4	\N	CASH	\N
214	11	13	26.378604679494785	50.12143772095442	26.3786, 50.1214	26.377257828636253	50.11928524821997	26.3773, 50.1193	COMPLETED	ECONOMY	2.11	2.11	0.534	3	2026-07-10 17:21:08.671465	2026-07-10 17:21:13.875263	2026-07-10 17:21:46.82198	2026-07-10 17:22:11.94362	\N	\N	\N	\N	\N	\N	2026-07-10 17:21:28.572588	\N	15	ECONOMY	4	\N	CASH	\N
202	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-08 23:33:10.361053	2026-07-08 23:33:21.770296	2026-07-08 23:33:36.914682	2026-07-08 23:33:53.812701	\N	\N	\N	\N	\N	\N	2026-07-08 23:33:28.539015	\N	15	ECONOMY	4	\N	WALLET	\N
209	6	13	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-09 15:55:30.431576	2026-07-09 15:55:38.440284	2026-07-09 15:55:55.682144	2026-07-09 15:55:57.681598	\N	\N	\N	\N	\N	\N	2026-07-09 15:55:53.027815	\N	15	ECONOMY	4	\N	CASH	\N
207	6	7	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	COMPLETED	ECONOMY	2.94	2.94	4.692	8	2026-07-09 15:47:48.025543	2026-07-09 15:47:57.998897	2026-07-09 15:49:56.476217	2026-07-09 15:50:08.1526	\N	\N	\N	\N	\N	\N	2026-07-09 15:49:23.603007	\N	15	ECONOMY	4	\N	CASH	\N
212	11	13	26.378638960725	50.12130796909332	26.3786, 50.1214	26.400066007539273	50.11714953929186	26.4001, 50.1171	COMPLETED	ECONOMY	2.94	2.94	4.685	7	2026-07-09 21:33:53.360818	2026-07-09 21:34:14.14106	2026-07-09 21:37:09.891332	2026-07-09 21:42:25.843095	\N	\N	\N	\N	\N	\N	2026-07-09 21:35:06.16084	\N	15	ECONOMY	4	\N	CASH	\N
210	6	13	26.379814105772834	50.120030734688044	KSA-DAM-Hajar-Al Iqtisad	26.40788985252553	50.11706655845046	KSA-DAM-حي الشفاء-مكه المكرمه	CANCELLED	ECONOMY	2.94	\N	4.692	8	2026-07-09 15:59:15.504752	2026-07-09 15:59:24.296762	\N	\N	2026-07-09 15:59:35.273011	testing	\N	\N	\N	\N	\N	\N	15	ECONOMY	2	\N	CASH	\N
216	11	13	26.378604679494785	50.12143772095442	26.3786, 50.1214	26.399612564467535	50.06567224860191	26.3996, 50.0657	COMPLETED	ECONOMY	3.68	3.68	8.41	13	2026-07-10 17:45:22.874662	2026-07-10 17:45:48.919888	2026-07-10 17:48:55.954585	2026-07-10 18:02:45.19194	\N	\N	\N	\N	\N	\N	2026-07-10 17:46:55.109519	\N	15	ECONOMY	4	\N	CASH	\N
213	11	13	26.40051523212383	50.11876657605171	26.4005, 50.1188	26.378631775450202	50.121402852237225	26.3786, 50.1214	COMPLETED	ECONOMY	3.81	3.81	9.031	12	2026-07-09 22:38:15.326998	2026-07-09 22:38:19.434977	2026-07-09 22:38:33.288324	2026-07-09 22:43:58.387095	\N	\N	\N	\N	\N	\N	2026-07-09 22:38:24.50123	\N	15	ECONOMY	4	\N	CASH	\N
215	11	13	26.378604679494785	50.12143772095442	26.3786, 50.1214	26.377662465139014	50.11912565678358	26.3777, 50.1191	COMPLETED	ECONOMY	2.11	2.11	0.571	3	2026-07-10 17:22:44.527012	2026-07-10 17:22:50.156626	2026-07-10 17:23:46.274039	2026-07-10 17:24:13.720731	\N	\N	\N	\N	\N	\N	2026-07-10 17:23:05.503728	\N	15	ECONOMY	4	\N	CASH	\N
219	6	\N	26.397819770707606	50.14566845447015	26.3983, 50.1448	26.383770196890072	50.135561435086885	26.3838, 50.1356	CANCELLED	ECONOMY	2.91	\N	4.527	6	2026-07-13 09:20:07.78748	\N	\N	\N	2026-07-13 09:23:39.829248	Rider cancelled search	\N	\N	\N	\N	\N	\N	15	ECONOMY	1	\N	CASH	\N
220	6	\N	26.397819770707606	50.14566845447015	26.3983, 50.1448	26.383770196890072	50.135561435086885	26.3838, 50.1356	CANCELLED	ECONOMY	2.91	\N	4.527	6	2026-07-13 09:50:10.489428	\N	\N	\N	2026-07-13 09:51:17.105258	Rider cancelled search	\N	\N	\N	\N	\N	2026-07-13 09:51:11.818525	15	ECONOMY	2	\N	CASH	\N
221	6	\N	26.397981477466807	50.145541519707166	26.3980, 50.1454	26.39415630541179	50.142419941262474	26.3942, 50.1424	CANCELLED	ECONOMY	2.12	\N	0.623	2	2026-07-13 10:01:38.867246	\N	\N	\N	2026-07-13 10:01:48.291561	Rider cancelled search	\N	\N	\N	\N	\N	\N	15	ECONOMY	1	\N	CASH	\N
\.


--
-- Data for Name: scheduled_rides; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scheduled_rides (id, cancellation_reason, cancelled_at, created_at, dropoff_address, dropoff_latitude, dropoff_longitude, estimated_distance, estimated_duration, estimated_fare, pickup_address, pickup_latitude, pickup_longitude, ride_type, scheduled_at, status, rider_id, arrived_at, assigned_at, expired_at, pickup_code, pickup_code_verified_at, reminder_sent_at, started_at, version, driver_id) FROM stdin;
1	\N	\N	2026-07-13 09:16:53.329415	العثيم مول 	0	0	\N	\N	\N	حي الفردوس الدمام	0	0	ECONOMY	2026-07-16 00:00:00	PENDING	6	\N	\N	\N	\N	\N	\N	\N	\N	\N
2	\N	\N	2026-07-13 11:10:30.873241	7099, 3575, Dammam 32234, Saudi Arabia	26.391417125842608	50.13448403891109	\N	\N	\N	EDGA4853, 4853 King Fahd Road, 7608, Dammam 32234, Saudi Arabia	26.398035527587464	50.14568536496515	ECONOMY	2026-07-15 01:30:00	PENDING	6	\N	\N	\N	\N	\N	\N	\N	\N	\N
9	Cancelled by user	2026-07-13 16:17:54.541905	2026-07-13 15:41:18.650695	EDGA4700, 4700 King Fahd Road, 7712, Dammam 32234, Saudi Arabia	26.38477787732598	50.134532541104754	\N	\N	\N	EDGA4700, 4700 King Fahd Road, 7712, Dammam 32234, Saudi Arabia	26.39832914287554	50.144831605257515	ECONOMY	2026-07-15 16:00:00	CANCELLED	6	\N	\N	\N	\N	\N	\N	\N	1	\N
10	Cancelled by user	2026-07-13 16:24:00.46842	2026-07-13 16:23:44.300376	MQPG+757 Othaim Mall, Ar Rabwah, Riyadh 12839, Saudi Arabia	24.685663198478945	46.775428242981434	\N	\N	\N	Othaim Mall, طريق الظهران،، Al Mubarraz Saudi Arabia	25.400436	49.577898	ECONOMY	2026-07-14 17:00:00	CANCELLED	6	\N	\N	\N	\N	\N	\N	\N	1	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, created_at, device_token, email, full_name, is_online, is_verified, password, username, role, country_code, normalized_phone, phone_number, phone_verified) FROM stdin;
12	2026-05-31 17:22:10.964823	cF5KxrHvRF2wwCl4BDI00l:APA91bHhIxLzNNfBcUlxFgd38n56SxykpQCpLCbfU9h243hZjHcai7D8mGUcN5p1u0S4Y_rA_z8fnl2NBy1ZVgPf53t6s8gQhS2oA9Bixw8sLiepaGnMTSc	aboudiassi2014@gmail.com	Abdulrahman	t	t	$2a$12$oKxd0Kczk9rikw4Y1gnR.uvfACdTb3x0iuimRXkNGPZeFyvMDRjmG	aboudiassi2014	RIDER	\N	\N	\N	f
6	2026-05-11 15:54:42.199344	cgI0xipjQLmcO9tZwHrPzC:APA91bHRESKP2-khssqA5geH6V18FlZrKzVpmptRSY3uJMvygW3NjPgAWeMNSfLwdja42_mwLZaW0RDu5cwNvRWxXy33o5unHeInsy2tTT_eMsuzS2jnazI	rider2@test.com	John Rider	t	t	$2a$12$/OC8Pk.bin2xh7cenB/hhOtlmPMlZjdPTMbUt.3.vc.su9JVjkgFS	rider2	RIDER	\N	\N	\N	f
7	2026-05-11 15:56:05.741125	ec0NzUXUQk-CctT5Wg67yY:APA91bEXatVEzP3Zqzd9s3zyPVupcnHSZ35ogJJNk1t2mM8sW2TUovamGjF5VnF4re7gJwbvZ82BRXXI_hxD1WyfFM-Wzutmw9YbWfYKlKo9VwCNUjgVHyc	driver2@test.com	Mike Driver	t	t	$2a$12$3lVBfmRWU55HyE74D6bfa.hKbCdeKcNDmtLkbwyxTYQCQM5bIB9wq	driver2	DRIVER	\N	\N	\N	f
15	2026-07-08 22:14:06.909472	\N	testdriver@test.com	Test Driver	f	t	$2a$12$yls1CaNaAMp.30JAZV.PnurignETLmCFD.fvu.72iQfFOGFMjuYE.	testdriver	DRIVER	+966	+966966500000000	+966500000000	f
14	2026-07-06 16:24:19.567547	cRFrvfB8QTmdAkMxk29PMw:APA91bENovxHOhz_DCa0F7Gs7TJ-PDilOTViP9nOOGoPiOHcPoVT4KMKFYV2Zi2xijkTM5BPNgMfjcs2qCSng9VtrO928Cmu4F7mnym9PBwTGPkMVGvmadY	muasiassi@gmail.com	Mustaasai	f	t	$2a$12$Tu/EyV7LTuaAOm7l3QqGZOkKC8JGZqCKm.SWiwl0AbcBaSn8vtDby	muasiassi	DRIVER	+966	+966551228634	551228634	f
10	2026-05-14 11:50:53.89872	\N	driverman2@test.com	driverman2	t	t	$2a$12$QXeAmdAXky8E6gtasB6U8O1H5LEY0cLpW0mb9apGM7roooGZ2zSDe	driverman2	DRIVER	\N	\N	\N	f
9	2026-05-14 11:48:23.510304	\N	riderman1@test.com	Riderman1	t	t	$2a$12$PJzrcNHcIKbIBDKdG/GPWu89bQQMv7fvlz8I29ktJv.NwaaZDOfhS	riderman1	RIDER	\N	\N	\N	f
1	2026-05-05 16:40:07.642897	cgI0xipjQLmcO9tZwHrPzC:APA91bHRESKP2-khssqA5geH6V18FlZrKzVpmptRSY3uJMvygW3NjPgAWeMNSfLwdja42_mwLZaW0RDu5cwNvRWxXy33o5unHeInsy2tTT_eMsuzS2jnazI	muasi@yahoo.com	Mustafa	t	f	$2a$12$QC9rzz3Ryac2mwUSs1fjZuFHAbnhVIMC8jqWhL4ejyhvLUXYsQ.eK	\N	ADMIN	\N	\N	0503604578	f
13	2026-06-19 21:18:46.958491	engSc-UkTzm9ZHp7mvUCha:APA91bFOPP_2-a9DFfs2Du0iSUW4YNZPzoymiSPngt87hRF7ywcHPTKIROTZzNVRd-8npCs3gHG492RadLm7mSzEWYERWAkounjrbMTAwNaOcr_uoryit-E	eng.mustafa83@yahoo.com	muasi	t	t	$2a$12$SCK/svdRrSnveJFAH5l0zOFPBqMoAJqfyGZCIfWbUIQiOJVELUrF.	muasi	DRIVER	\N	\N	\N	f
11	2026-05-31 16:17:32.532025	\N	diarjojo89@gmail.com	jomana	t	t	$2a$12$e7iRwNgkGw5W0MJiBm5WKeY8x1rx8X0vlGTMQiHFhHQkIMH0LP7ua	diarjojo89	RIDER	\N	\N	\N	f
3	2026-05-06 11:24:32.012239	\N	man2@yahoo.com	man2	f	t	$2a$12$gcatjUVFr26Hmew3xlpcS.OOUjqjGQviUwFP9S8rKmaZUxOXGnYiS	man2	RIDER	\N	\N	\N	f
2	2026-05-06 11:07:40.007204	\N	man1@yahoo.com	man1	f	t	$2a$12$OMz3VgQFAQz1EjIGaYhoq.wQmqvsnILNPBOVF2zPMDjQX2fGjPQQm	man1	RIDER	\N	\N	\N	f
4	2026-05-11 10:43:26.710424	\N	rider1@test.com	John Rider	f	t	$2a$12$oZrpqztr0y.4QvUqTck7SeeFP5Yby78QEHfVnXsUaL6j1TVSD2K2O	rider1	RIDER	\N	\N	\N	f
5	2026-05-11 10:48:47.248375	\N	driver1@test.com	Mike Driver	f	t	$2a$12$nmz2mectSdQYLa24sJooD.hEhm2IxyNXXjBUJbN3u4b9mr0i3C0cy	driver1	DRIVER	\N	\N	\N	f
8	2026-05-12 09:45:34.376564	\N	postman_rider@test.com	Postman Rider	t	t	$2a$12$wT7P9rHhwcIJywSzgIxe0.Zsj8wth2yVJbPf/DYSDGGilUPnzZ3qe	postman_rider	RIDER	\N	\N	\N	f
\.


--
-- Data for Name: wallet_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wallet_transactions (id, amount, created_at, description, type, ride_id, user_id) FROM stdin;
1	-2.57	2026-06-29 15:01:12.473704	Trip fare for ride #156	PAYMENT	156	6
2	-2.57	2026-06-29 15:15:38.886716	Trip fare for ride #157	PAYMENT	157	6
3	-9.59	2026-06-30 09:55:58.743215	Trip fare for ride #159	PAYMENT	159	6
4	-2.15	2026-06-30 21:11:11.308595	Trip fare for ride #169	PAYMENT	169	6
5	-2.11	2026-06-30 21:16:35.217278	Trip fare for ride #170	PAYMENT	170	6
6	-2.11	2026-07-01 19:33:29.595943	Trip fare for ride #172	PAYMENT	172	6
7	-2.12	2026-07-02 20:52:05.742688	Trip fare for ride #174	PAYMENT	174	6
8	-3.34	2026-07-03 18:27:43.782186	Trip fare for ride #179	PAYMENT	179	6
9	-2.88	2026-07-03 21:27:01.674173	Trip fare for ride #183	PAYMENT	183	6
14	-6.17	2026-07-07 00:09:15.710606	Trip fare for ride #197	PAYMENT	197	6
15	-2.94	2026-07-07 10:01:51.905764	Trip fare for ride #198	PAYMENT	198	6
\.


--
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wallets (id, balance, created_at, updated_at, user_id) FROM stdin;
1	-38.55	2026-06-29 15:01:12.458743	2026-07-07 10:01:51.904263	6
\.


--
-- Name: driver_earnings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.driver_earnings_id_seq', 21, true);


--
-- Name: driver_notification_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.driver_notification_queue_id_seq', 6, true);


--
-- Name: driver_profiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.driver_profiles_id_seq', 5, true);


--
-- Name: game_rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.game_rooms_id_seq', 1, false);


--
-- Name: location_updates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.location_updates_id_seq', 2806, true);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 207, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 171, true);


--
-- Name: otp_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.otp_codes_id_seq', 17, true);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_id_seq', 94, true);


--
-- Name: profile_photos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profile_photos_id_seq', 1, false);


--
-- Name: ratings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ratings_id_seq', 15, true);


--
-- Name: ride_audit_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ride_audit_events_id_seq', 789, true);


--
-- Name: ride_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ride_events_id_seq', 16, true);


--
-- Name: rides_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rides_id_seq', 221, true);


--
-- Name: scheduled_rides_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scheduled_rides_id_seq', 10, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 15, true);


--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wallet_transactions_id_seq', 15, true);


--
-- Name: wallets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wallets_id_seq', 17, true);


--
-- Name: driver_earnings driver_earnings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_earnings
    ADD CONSTRAINT driver_earnings_pkey PRIMARY KEY (id);


--
-- Name: driver_notification_queue driver_notification_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_notification_queue
    ADD CONSTRAINT driver_notification_queue_pkey PRIMARY KEY (id);


--
-- Name: driver_profiles driver_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_profiles
    ADD CONSTRAINT driver_profiles_pkey PRIMARY KEY (id);


--
-- Name: driver_profiles driver_profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_profiles
    ADD CONSTRAINT driver_profiles_user_id_key UNIQUE (user_id);


--
-- Name: game_rooms game_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_rooms
    ADD CONSTRAINT game_rooms_pkey PRIMARY KEY (id);


--
-- Name: location_updates location_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_updates
    ADD CONSTRAINT location_updates_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: otp_codes otp_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_codes
    ADD CONSTRAINT otp_codes_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: payments payments_ride_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_ride_id_key UNIQUE (ride_id);


--
-- Name: profile_photos profile_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_photos
    ADD CONSTRAINT profile_photos_pkey PRIMARY KEY (id);


--
-- Name: ratings ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (id);


--
-- Name: ride_audit_events ride_audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ride_audit_events
    ADD CONSTRAINT ride_audit_events_pkey PRIMARY KEY (id);


--
-- Name: ride_events ride_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ride_events
    ADD CONSTRAINT ride_events_pkey PRIMARY KEY (id);


--
-- Name: rides rides_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rides
    ADD CONSTRAINT rides_pkey PRIMARY KEY (id);


--
-- Name: scheduled_rides scheduled_rides_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_rides
    ADD CONSTRAINT scheduled_rides_pkey PRIMARY KEY (id);


--
-- Name: driver_earnings uk_5rj07h292cnksd3wft83hoh; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_earnings
    ADD CONSTRAINT uk_5rj07h292cnksd3wft83hoh UNIQUE (ride_id);


--
-- Name: users uk_6dotkott2kjsp8vw4d0m25fb7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk_6dotkott2kjsp8vw4d0m25fb7 UNIQUE (email);


--
-- Name: users uk_ljyi7xdgbps3tbudobn1q32y6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk_ljyi7xdgbps3tbudobn1q32y6 UNIQUE (normalized_phone);


--
-- Name: users uk_r43af9ap4edm43mmtq01oddj6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk_r43af9ap4edm43mmtq01oddj6 UNIQUE (username);


--
-- Name: wallets uk_sswfdl9fq40xlkove1y5kc7kv; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT uk_sswfdl9fq40xlkove1y5kc7kv UNIQUE (user_id);


--
-- Name: ratings ukf99pgx46c2qfyfsny2ty1rfny; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ukf99pgx46c2qfyfsny2ty1rfny UNIQUE (ride_id, rater_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: wallet_transactions wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: idx_ae_actor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ae_actor_id ON public.ride_audit_events USING btree (actor_id);


--
-- Name: idx_ae_corr_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ae_corr_id ON public.ride_audit_events USING btree (correlation_id);


--
-- Name: idx_ae_event_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ae_event_type ON public.ride_audit_events USING btree (event_type);


--
-- Name: idx_ae_ride_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ae_ride_id ON public.ride_audit_events USING btree (ride_id);


--
-- Name: idx_ae_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ae_timestamp ON public.ride_audit_events USING btree ("timestamp");


--
-- Name: idx_sender_receiver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sender_receiver ON public.messages USING btree (sender_id, receiver_id);


--
-- Name: idx_sent_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sent_at ON public.messages USING btree (sent_at);


--
-- Name: driver_profiles driver_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_profiles
    ADD CONSTRAINT driver_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: driver_earnings fk40iukemxylcjcehcy74223h0k; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_earnings
    ADD CONSTRAINT fk40iukemxylcjcehcy74223h0k FOREIGN KEY (driver_id) REFERENCES public.users(id);


--
-- Name: messages fk4ui4nnwntodh6wjvck53dbk9m; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk4ui4nnwntodh6wjvck53dbk9m FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: notifications fk9y21adhxn0ayjhfocscqox7bh; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk9y21adhxn0ayjhfocscqox7bh FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: wallets fkc1foyisidw7wqqrkamafuwn4e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT fkc1foyisidw7wqqrkamafuwn4e FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: wallet_transactions fkdyuech39l6fnp1ccls10j7e90; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT fkdyuech39l6fnp1ccls10j7e90 FOREIGN KEY (ride_id) REFERENCES public.rides(id);


--
-- Name: scheduled_rides fkhmxt4868l2kkhfgw362q536ty; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_rides
    ADD CONSTRAINT fkhmxt4868l2kkhfgw362q536ty FOREIGN KEY (driver_id) REFERENCES public.users(id);


--
-- Name: driver_earnings fkitvlfbrmkk0k354jicbkob600; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.driver_earnings
    ADD CONSTRAINT fkitvlfbrmkk0k354jicbkob600 FOREIGN KEY (ride_id) REFERENCES public.rides(id);


--
-- Name: scheduled_rides fkrqq7suj7910mydy7p384542rg; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduled_rides
    ADD CONSTRAINT fkrqq7suj7910mydy7p384542rg FOREIGN KEY (rider_id) REFERENCES public.users(id);


--
-- Name: wallet_transactions fkrtsa3qtjhd0rn4xb92na03vd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT fkrtsa3qtjhd0rn4xb92na03vd FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: messages fkt05r0b6n0iis8u7dfna4xdh73; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fkt05r0b6n0iis8u7dfna4xdh73 FOREIGN KEY (receiver_id) REFERENCES public.users(id);


--
-- Name: location_updates location_updates_ride_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_updates
    ADD CONSTRAINT location_updates_ride_id_fkey FOREIGN KEY (ride_id) REFERENCES public.rides(id);


--
-- Name: location_updates location_updates_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location_updates
    ADD CONSTRAINT location_updates_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payments payments_ride_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_ride_id_fkey FOREIGN KEY (ride_id) REFERENCES public.rides(id);


--
-- Name: ratings ratings_ratee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_ratee_id_fkey FOREIGN KEY (ratee_id) REFERENCES public.users(id);


--
-- Name: ratings ratings_rater_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_rater_id_fkey FOREIGN KEY (rater_id) REFERENCES public.users(id);


--
-- Name: ratings ratings_ride_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_ride_id_fkey FOREIGN KEY (ride_id) REFERENCES public.rides(id);


--
-- Name: rides rides_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rides
    ADD CONSTRAINT rides_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.users(id);


--
-- Name: rides rides_rider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rides
    ADD CONSTRAINT rides_rider_id_fkey FOREIGN KEY (rider_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict chZxoPqVgz6Q2WApY0b4tlWgClVhL9PQP8WLeVHk9NSdI5jFuzB68G5HsejaJdb

